import os
import numpy as np
import matplotlib.pyplot as plt
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.models import load_model
from PIL import Image

# โหลดโมเดล
model = load_model('C:/Users/Acer/Desktop/Project/mobilenetv2/ผลลัพธ์/train3/mobilenetv2_age_classifier_best.keras')

# โฟลเดอร์บันทึกผลลัพธ์
SAVE_DIR = "C:/Users/Acer/Desktop/Project/mobilenetv2/ผลลัพธ์/train3"
os.makedirs(SAVE_DIR, exist_ok=True)

# ชื่อคลาส (ตามที่เทรนไว้)
class_names = [
    'cat_adult', 'cat_kitten', 'cat_senior', 'cat_young',
    'dog_adult', 'dog_puppy', 'dog_senior', 'dog_young'
]

def preprocess_images(imgs):
    """
    รับ input: รูปเดียว (PIL.Image) หรือ list ของรูป
    คืนค่า: batch (N, 224, 224, 3)
    """
    if not isinstance(imgs, list):
        imgs = [imgs]

    batch = []
    for img in imgs:
        img = img.resize((224, 224))                # Resize ให้เท่ากับตอนเทรน
        img_array = image.img_to_array(img)         # (224, 224, 3)
        img_array = preprocess_input(img_array)     # Normalize ให้เป็น -1 ถึง 1
        batch.append(img_array)

    return np.array(batch), imgs  # คืนทั้ง batch และรูปเดิม (เผื่อแสดงผล)

# ====== ตัวอย่างการใช้งาน ======

# โหลดรูป (1 หรือหลายรูปก็ได้)
"""
img1 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/4461d213-de3c-4a42-a5c1-06c654ae50e0.jpg')
img2 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/dbb7cb2e-ee69-4dc6-8ff9-423f2e2f7815.jpg')
img3 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Charlotte.jpg')
img4 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/BETTY.jpg')
img5 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/ELAINE.jpg')
img6 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/EEVEE.jpg')
img7 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Paolo.jpg')
img8 = Image.open('C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Cosette.jpg')
inputs, original_imgs = preprocess_images([img1, img2, img3, img4, img5, img6, img7, img8])  # หลายรูป
"""
# inputs, original_imgs = preprocess_images(img1)  # รูปเดียว

# ====== โหลดรูป ======
img_paths = [
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/4461d213-de3c-4a42-a5c1-06c654ae50e0.jpg',
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/dbb7cb2e-ee69-4dc6-8ff9-423f2e2f7815.jpg',
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Delta.jpg',
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Toby.jpg',
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/ELAINE.jpg',
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Lambchop.jpg',
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Paolo.jpg',
    'C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Cindi.jpg'
]

imgs = [Image.open(p) for p in img_paths]
inputs, original_imgs = preprocess_images(imgs)

# ทำนาย
preds = model.predict(inputs)
"""
# แสดงผล
for i, p in enumerate(preds):
    pred_class = np.argmax(p)
    confidence = p[pred_class]
    pred_label = class_names[pred_class]

    print(f"รูปที่ {i+1}: คลาส = {pred_label}, ความมั่นใจ = {confidence*100:.2f}%")

    # แสดงภาพ
    plt.imshow(original_imgs[i])
    plt.title(f"Predicted: {pred_label} ({confidence*100:.1f}%)")
    plt.axis("off")
    plt.show()
"""
# ไฟล์ผลลัพธ์รวม
results_file = os.path.join(SAVE_DIR, "results.txt")
with open(results_file, "w", encoding="utf-8") as f:
    for i, (p, path) in enumerate(zip(preds, img_paths)):
        pred_class = np.argmax(p)
        confidence = p[pred_class]
        pred_label = class_names[pred_class]

        result_text = f"รูปที่ {i+1} ({os.path.basename(path)}): {pred_label}, ความมั่นใจ = {confidence*100:.2f}%"
        print(result_text)
        f.write(result_text + "\n")

        # บันทึกรูปพร้อม label
        plt.imshow(original_imgs[i])
        plt.title(f"{pred_label} ({confidence*100:.1f}%)")
        plt.axis("off")
        save_path = os.path.join(SAVE_DIR, f"pred_{i+1}_{pred_label}.jpg")
        plt.savefig(save_path, bbox_inches="tight")
        plt.close()

print(f"\n✅ ผลลัพธ์ถูกบันทึกที่: {SAVE_DIR}")