from ultralytics import YOLO

# Load a pretrained YOLO11n model
model = YOLO("yolo11n.pt")

# Train the model on the COCO8 dataset for 100 epochs
train_results = model.train(
    data="C:/Users/Acer/Desktop/Project/yolov11/datasets_breeds/data.yaml",  # Path to dataset configuration file
    epochs=100,  # Number of training epochs
    imgsz=640,  # Image size for training
    device="0",  # Device to run on (e.g., 'cpu', 0, [0,1,2,3])
    workers=0,  # จำนวน worker สำหรับโหลดข้อมูล (0 = โหลดทีละ batch, ใช้สำหรับ Windows ป้องกัน crash)
    patience=20, # จำนวนรอบที่รอถ้าความแม่นยำไม่ดีขึ้นก่อนหยุด early stopping
    lr0=0.0001, # ค่า learning rate เริ่มต้น (0.0001 ช้าและปลอดภัยต่อการ overfit)
    dropout=0.1,            # ลด overfitting ด้วย dropout
    label_smoothing=0.01, # ปรับ label ให้เรียบขึ้น ลด overconfidence (0.01)
    warmup_epochs=2    # จำนวน epochs ที่ใช้ "วอร์มอัพ" learning rate จากต่ำขึ้นไปก่อนเข้า training ปกติ
)

# Evaluate the model's performance on the validation set
metrics = model.val()

dog_classes = [0, 4, 5, 8, 9, 10, 14, 15, 17, 19]  # index ของคลาสหมา
cat_classes = [1, 2, 3, 6, 7, 11, 12, 13, 16, 18]  # index ของคลาสแมว

# คำนวณค่าเฉลี่ย mAP50 สำหรับหมา
dog_map50 = sum([metrics.box.maps[i] for i in dog_classes]) / len(dog_classes)

# คำนวณค่าเฉลี่ย mAP50 สำหรับแมว
cat_map50 = sum([metrics.box.maps[i] for i in cat_classes]) / len(cat_classes)

# แสดงผลลัพธ์
print(f"Dog overall mAP50: {dog_map50:.3f}")
print(f"Cat overall mAP50: {cat_map50:.3f}")