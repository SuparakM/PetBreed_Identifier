import os
import shutil
import random
from collections import defaultdict

# พาธต้นทาง
image_dir = 'C:/Users/Acer/Desktop/Project/yolov11/datasets/train/images'
label_dir = 'C:/Users/Acer/Desktop/Project/yolov11/datasets/train/labels'

# พาธปลายทาง
output_base = 'C:/Users/Acer/Desktop/Project/yolov11/datasets_breeds'
splits = ['train', 'valid', 'test']
split_ratio = {'train': 0.8, 'valid': 0.15, 'test': 0.05}

# สร้างโฟลเดอร์สำหรับชุดข้อมูลที่แบ่งแล้ว
for split in splits:
    os.makedirs(os.path.join(output_base, split, 'images'), exist_ok=True)
    os.makedirs(os.path.join(output_base, split, 'labels'), exist_ok=True)

# Step 1: จัดกลุ่มภาพตามคลาส
class_to_files = defaultdict(list)

for label_file in os.listdir(label_dir):
    if not label_file.endswith('.txt'):
        continue
    path = os.path.join(label_dir, label_file)
    with open(path, 'r') as f:
        lines = f.readlines()
        classes_in_file = set(int(line.split()[0]) for line in lines if len(line.split()) >= 5)
        for cls in classes_in_file:
            image_filename = os.path.splitext(label_file)[0] + '.jpg'
            class_to_files[cls].append(image_filename)

# Step 2: แบ่งข้อมูลโดยให้คลาสมีสัดส่วนใกล้เคียงกัน
final_split_files = {'train': set(), 'valid': set(), 'test': set()}

for cls, files in class_to_files.items():
    unique_files = list(set(files))  # ป้องกันซ้ำ
    random.shuffle(unique_files)
    total = len(unique_files)

    train_count = int(total * split_ratio['train'])
    val_count = int(total * split_ratio['valid'])
    test_count = total - train_count - val_count  # ส่วนที่เหลือ

    final_split_files['train'].update(unique_files[:train_count])
    final_split_files['valid'].update(unique_files[train_count:train_count + val_count])
    final_split_files['test'].update(unique_files[train_count + val_count:])

# Step 3: คัดลอกไฟล์รูปและ label ไปยังโฟลเดอร์ปลายทาง
def copy_files(split, filenames):
    for img_file in filenames:
        label_file = os.path.splitext(img_file)[0] + '.txt'

        src_img = os.path.join(image_dir, img_file)
        src_lbl = os.path.join(label_dir, label_file)

        dst_img = os.path.join(output_base, split, 'images', img_file)
        dst_lbl = os.path.join(output_base, split, 'labels', label_file)

        if os.path.exists(src_img) and os.path.exists(src_lbl):
            shutil.copy2(src_img, dst_img)
            shutil.copy2(src_lbl, dst_lbl)

# คัดลอกแต่ละชุด
for split in splits:
    copy_files(split, final_split_files[split])
    print(f"{split}: {len(final_split_files[split])} files copied.")

print("✅ Dataset split completed.")