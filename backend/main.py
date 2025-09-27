from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import shutil, uuid, os, cv2, numpy as np
from ultralytics import YOLO
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
import json

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# โฟลเดอร์ชั่วคราว
UPLOAD_FOLDER = "temp_images"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# โหลดโมเดล YOLOv11 สำหรับการจำแนกสายพันธุ์ สุนัขและแมว
yolo_model = YOLO("best.pt")
# โหลดโมเดล MobileNetV2 สำหรับการจำแนกอายุ
age_model = "mobilenetv2.tflite"

# โหลด TFLite interpreter
age_interpreter = tf.lite.Interpreter(model_path=age_model)
age_interpreter.allocate_tensors()

# เตรียมรายละเอียด input/output ของ TFLite
age_input_details = age_interpreter.get_input_details()
age_output_details = age_interpreter.get_output_details()

# ช่วงวัย (ตามที่โมเดลเทรนไว้)
age_labels = ["cat_kitten","cat_young","cat_adult","cat_senior",
              "dog_puppy","dog_young","dog_adult","dog_senior"]

# Mapping cat ↔ dog เพื่อให้ YOLO + Age model ตรงกัน
age_mapping = {
    # cat → dog
    "cat_kitten": "dog_puppy",
    "cat_young": "dog_young",
    "cat_adult": "dog_adult",
    "cat_senior": "dog_senior",
    # dog → cat
    "dog_puppy": "cat_kitten",
    "dog_young": "cat_young",
    "dog_adult": "cat_adult",
    "dog_senior": "cat_senior"
}

# =========================
# Helper Functions
# =========================
def preprocess_for_age(crop_img):
    """
    รับ crop_img (BGR uint8) -> คืนค่าเป็น array shape (1,224,224,3) float32 ที่ preprocess_input ทำแล้ว
    NOTE: ถ้า TFLite รองรับ uint8 จะถูกแปลงใน predict function
    """
    if crop_img is None or crop_img.size == 0:
        return None
    # Convert BGR -> RGB
    img = cv2.cvtColor(crop_img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (224,224))
    img = np.expand_dims(img, axis=0).astype(np.float32)  # (1,224,224,3)
    # ใช้ preprocess_input ของ MobileNetV2 ซึ่งจะ scale เป็น [-1,1]
    img = preprocess_input(img)
    return img

def tflite_predict_age(interpreter, input_details, output_details, preprocessed_img):
    """
    ทำ inference ด้วย tflite interpreter
    - preprocessed_img: numpy array float32 shape (1,224,224,3) in [-1,1]
    - จัดการกรณี input dtype เป็น uint8 (quantized) หรือ float32
    คืนค่า: (age_idx, probs_array) หรือ (None, None) ถ้ามีปัญหา
    """
    if preprocessed_img is None:
        return None, None

    input_dtype = input_details[0]['dtype']
    input_index = input_details[0]['index']
    output_index = output_details[0]['index']

    # จัดเตรียม input ตาม dtype ของ interpreter
    if input_dtype == np.uint8:
        # ถ้าโมเดล quantized รับ uint8, แปลงจาก [-1,1] -> [0,255] (ประมาณ)
        # วิธีแปลงนี้ขึ้นกับวิธีแปลงที่ใช้ตอน convert tflite; ปรับได้ถ้าต้องการ
        input_data = ((preprocessed_img + 1.0) * 127.5).astype(np.uint8)
    else:
        # default float32
        input_data = preprocessed_img.astype(np.float32)

    try:
        interpreter.set_tensor(input_index, input_data)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_index)  # shape (1, num_classes)
        probs = np.squeeze(output_data)
        # ถ้า output ยังไม่ normalized ให้ softmax
        if probs.ndim == 1 and not (0.99 <= probs.sum() <= 1.01):
            e = np.exp(probs - np.max(probs))
            probs = e / e.sum()
        age_idx = int(np.argmax(probs))
        return age_idx, probs
    except Exception as e:
        # ถ้าการ inference ผิดพลาด ให้คืน None
        print("TFLite inference error:", e)
        return None, None

# =========================
# Endpoint
# =========================
@app.post("/analyze")
async def analyze_images(files: list[UploadFile] = File(...)):
    """
    รับไฟล์รูปหลายรูป, ทำการตรวจจับด้วย YOLO แล้วประเมินอายุด้วย TFLite model
    คืน JSON ที่มี path ของรูปผลลัพธ์ในเซิร์ฟเวอร์ และรายละเอียด detections
    """
    all_results = []

    for file in files:
        # บันทึกไฟล์ที่อัพโหลด
        file_id = str(uuid.uuid4())
        filename = file.filename
        file_path = os.path.join(UPLOAD_FOLDER, f"{file_id}_{filename}")
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # YOLO ตรวจจับ
        try:
            yolo_out = yolo_model(file_path)[0]  # ผลของ ultralytics
        except Exception as e:
            # ถ้า YOLO ผิดพลาด
            all_results.append({
                "original_file": filename,
                "error": f"YOLO inference error: {str(e)}"
            })
            continue

        detections = []
        cropped_animals = []

        # อ่านภาพเพื่อ crop
        img_cv_full = cv2.imread(file_path)
        if img_cv_full is None:
            all_results.append({
                "original_file": filename,
                "error": "ไม่สามารถอ่านไฟล์ภาพได้"
            })
            continue
        h_full, w_full = img_cv_full.shape[:2]

        # loop boxes
        for det in yolo_out.boxes:
            try:
                x1, y1, x2, y2 = det.xyxy[0].tolist()
                conf = float(det.conf[0])
                cls = int(det.cls[0])
                label = yolo_model.names[cls] if hasattr(yolo_model, "names") else str(cls)
                # clamp coords
                x1i, y1i = max(0, int(x1)), max(0, int(y1))
                x2i, y2i = min(w_full-1, int(x2)), min(h_full-1, int(y2))

                detections.append({
                    "label": label,
                    "confidence": conf,
                    "bbox": [x1i, y1i, x2i, y2i]
                })

                # crop image (ถ้าขนาดถูกต้อง)
                if x2i > x1i and y2i > y1i:
                    crop_img = img_cv_full[y1i:y2i, x1i:x2i]
                else:
                    crop_img = None
                cropped_animals.append(crop_img)
            except Exception as e:
                print("Error parsing detection:", e)
                continue

        if not detections:
            all_results.append({
                "original_file": filename,
                "message": "ไม่พบสัตว์ในภาพ (หลัง parse)"
            })
            if os.path.exists(file_path):
                os.remove(file_path)
            continue

        # ประเมินอายุแต่ละ crop ด้วย TFLite
        age_results = []
        for crop in cropped_animals:
            if crop is None or crop.size == 0:
                age_results.append(None)
                continue
            pre = preprocess_for_age(crop)  # float32 [-1,1]
            age_idx, probs = tflite_predict_age(
                age_interpreter,
                age_input_details,
                age_output_details,
                pre
            )
            if age_idx is None or probs is None:
                age_results.append(None)
            else:
                age_results.append({
                    "age_range": age_labels[age_idx] if age_idx < len(age_labels) else f"idx_{age_idx}",
                    "confidence": float(probs[age_idx]) if len(probs) > age_idx else float(np.max(probs)),
                })

        # จัด JSON ผลลัพธ์
        result = {
            "original_file": file.filename,
            "detections": []
        }
        for i, det in enumerate(detections):
            entry = {
                "label": det["label"],
                "confidence": det["confidence"],
                "bbox": det["bbox"]
            }
            if i < len(age_results) and age_results[i] is not None:
                predicted_age = age_results[i]["age_range"]
                predicted_conf = age_results[i]["confidence"]

                # ปรับอายุให้ตรงประเภทสัตว์จาก YOLO โดยใช้ mapping
                if "dog" in det["label"].lower():
                    entry["animalType"] = "dog"
                    if predicted_age in age_mapping and predicted_age.startswith("cat_"):
                        predicted_age = age_mapping[predicted_age]
                elif "cat" in det["label"].lower():
                    entry["animalType"] = "cat"
                    if predicted_age in age_mapping and predicted_age.startswith("dog_"):
                        predicted_age = age_mapping[predicted_age]

                entry.update({
                    "age_range": predicted_age,
                    "age_confidence": predicted_conf,
                })
            else:
                entry.update({
                    "age_range": None,
                    "age_confidence": None,
                })
                if det["label"].endswith("_cat"):
                    entry["animalType"] = "cat"
                elif det["label"].endswith("_dog"):
                    entry["animalType"] = "dog"

            result["detections"].append(entry)

        all_results.append(result)

        # ลบไฟล์ input ชั่วคราว
        if os.path.exists(file_path):
            os.remove(file_path)

    return JSONResponse(content={"results": all_results})