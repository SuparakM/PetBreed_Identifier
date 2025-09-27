import os
import shutil
import random
from collections import defaultdict

# พาธ dataset ที่มีโฟลเดอร์ย่อยตาม class
dataset_dir = 'C:/Users/Acer/Desktop/Project/mobilenetv2/datasets'

# พาธปลายทาง
output_base = 'C:/Users/Acer/Desktop/Project/mobilenetv2/datasets_age'
splits = ['train', 'valid', 'test']
split_ratio = {'train': 0.8, 'valid': 0.15, 'test': 0.05}

# Step 1: รวมไฟล์ .jpg จากแต่ละคลาส
class_to_files = defaultdict(list)

for class_folder in os.listdir(dataset_dir):
    class_path = os.path.join(dataset_dir, class_folder)
    if not os.path.isdir(class_path):
        continue

    for file in os.listdir(class_path):
        if file.endswith('.jpg'):
            image_path = os.path.join(class_path, file)
            class_to_files[class_folder].append(image_path)

# Step 2: สร้างโฟลเดอร์ปลายทาง
for split in splits:
    for class_name in class_to_files.keys():
        os.makedirs(os.path.join(output_base, split, class_name), exist_ok=True)

# Step 3: แบ่งข้อมูลและคัดลอก
def copy_images(split, image_paths, class_name):
    for image_path in image_paths:
        file_name = os.path.basename(image_path)
        dst = os.path.join(output_base, split, class_name, file_name)
        shutil.copy2(image_path, dst)

for class_name, image_list in class_to_files.items():
    random.shuffle(image_list)
    total = len(image_list)
    train_count = int(total * split_ratio['train'])
    val_count = int(total * split_ratio['valid'])
    test_count = total - train_count - val_count

    copy_images('train', image_list[:train_count], class_name)
    copy_images('valid', image_list[train_count:train_count + val_count], class_name)
    copy_images('test', image_list[train_count + val_count:], class_name)

    print(f"{class_name} → train: {train_count}, valid: {val_count}, test: {test_count}")

print("✅ Dataset split and ready for MobileNetV2 training.")