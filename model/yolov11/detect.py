from ultralytics import YOLO

model = YOLO('C:/Users/Acer/Desktop/Project/yolov11/runs/detect/train/weights/best.pt')

results = model("C:/Users/Acer/Desktop/Project/อ้างอิง/ทดสอบ/Winnie.jpeg")

results[0].show()