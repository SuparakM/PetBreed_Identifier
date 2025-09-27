import os
import tensorflow as tf
from tensorflow.keras.preprocessing import image_dataset_from_directory
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras import layers, models
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix, precision_recall_curve, average_precision_score, f1_score
import seaborn as sns

# --- ตั้งค่า path dataset ---
DATASET_DIR = "C:/Users/Acer/Desktop/Project/mobilenetv2/datasets_age"
SAVE_DIR = "C:/Users/Acer/Desktop/Project/mobilenetv2/ผลลัพธ์/train4"
os.makedirs(SAVE_DIR, exist_ok=True)

BATCH_SIZE = 32
IMG_SIZE = (224, 224)
EPOCHS = 100

# --- โหลด dataset ---
train_ds = image_dataset_from_directory(
    os.path.join(DATASET_DIR, 'train'),
    label_mode='categorical',
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=True
)
val_ds = image_dataset_from_directory(
    os.path.join(DATASET_DIR, 'valid'),
    label_mode='categorical',
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE
)
test_ds = image_dataset_from_directory(
    os.path.join(DATASET_DIR, 'test'),
    label_mode='categorical',
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    shuffle=False
)

# --- จำนวนคลาส ---
num_classes = len(train_ds.class_names)
class_names = train_ds.class_names
print("Classes:", class_names)

# --- Preprocessing ---
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.map(lambda x, y: (preprocess_input(x), y)).prefetch(AUTOTUNE)
val_ds = val_ds.map(lambda x, y: (preprocess_input(x), y)).prefetch(AUTOTUNE)
test_ds = test_ds.map(lambda x, y: (preprocess_input(x), y)).prefetch(AUTOTUNE)

# --- MobileNetV2 base ---
base_model = MobileNetV2(input_shape=IMG_SIZE + (3,), include_top=False, weights='imagenet')
base_model.trainable = False

# --- สร้างโมเดล ---
model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dense(128, activation='relu'),
    layers.Dropout(0.3),
    layers.Dense(num_classes, activation='softmax')
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# --- Callback ---
MODEL_PATH = os.path.join(SAVE_DIR, "mobilenetv2_age_classifier_best.keras")

callbacks = [
    tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True),
    tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=5, min_lr=1e-7),
    tf.keras.callbacks.ModelCheckpoint(MODEL_PATH, monitor='val_loss', save_best_only=True, verbose=1)
]

# --- เทรน ---
history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS,
    callbacks=callbacks
)

print(f"โมเดล val_loss ดีที่สุดถูกบันทึกไว้ที่: {MODEL_PATH}")

# --- โหลดโมเดลที่ดีที่สุด ---
model = tf.keras.models.load_model(MODEL_PATH)

# --- Training Accuracy ---
acc = history.history['accuracy']
val_acc = history.history['val_accuracy']
plt.figure(figsize=(8, 6))
plt.plot(acc, label='Train Accuracy')
plt.plot(val_acc, label='Validation Accuracy')
plt.title('Training & Validation Accuracy')
plt.xlabel('Epochs')
plt.ylabel('Accuracy')
plt.legend()
plt.grid()
plt.savefig(os.path.join(SAVE_DIR, "training_accuracy.png"))
plt.show()

# --- Training Loss ---
loss = history.history['loss']
val_loss = history.history['val_loss']
plt.figure(figsize=(8, 6))
plt.plot(loss, label='Train Loss')
plt.plot(val_loss, label='Validation Loss')
plt.title('Training & Validation Loss')
plt.xlabel('Epochs')
plt.ylabel('Loss')
plt.legend()
plt.grid()
plt.savefig(os.path.join(SAVE_DIR, "training_loss.png"))
#plt.show()

# --- Evaluate on test set ---
test_loss, test_acc = model.evaluate(test_ds)
print(f"\nTest Accuracy (best_val_loss): {test_acc:.4f}")

# --- Predict ---
y_pred = model.predict(test_ds)
y_true = np.concatenate([y for _, y in test_ds], axis=0)

y_pred_classes = np.argmax(y_pred, axis=1)
y_true_classes = np.argmax(y_true, axis=1)

# --- Classification Report ---
print("\nClassification Report:")
print(classification_report(y_true_classes, y_pred_classes, target_names=class_names))
print("Macro F1:", f1_score(y_true_classes, y_pred_classes, average="macro"))

# --- Confusion Matrix ---
cm = confusion_matrix(y_true_classes, y_pred_classes)
plt.figure(figsize=(10, 8))
sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
            xticklabels=class_names,
            yticklabels=class_names)
plt.title("Confusion Matrix")
plt.xlabel("Predicted")
plt.ylabel("True")
plt.savefig(os.path.join(SAVE_DIR, "confusion_matrix.png"))
#plt.show()

# --- F1-Confidence Curve ---
plt.figure(figsize=(12, 8))
for i, class_name in enumerate(class_names):
    precision, recall, thresholds = precision_recall_curve(y_true[:, i], y_pred[:, i])
    f1_scores = 2 * (precision * recall) / (precision + recall + 1e-8)
    best_idx = np.argmax(f1_scores)
    plt.plot(thresholds, f1_scores[:-1], label=f'{class_name} {f1_scores[best_idx]:.3f}')

precision_all, recall_all, thresholds_all = precision_recall_curve(y_true.ravel(), y_pred.ravel())
f1_all = 2 * (precision_all * recall_all) / (precision_all + recall_all + 1e-8)
best_all_idx = np.argmax(f1_all)
plt.plot(thresholds_all, f1_all[:-1], color='blue', linewidth=3,
         label=f'all classes {f1_all[best_all_idx]:.2f} at {thresholds_all[best_all_idx]:.3f}')

plt.xlabel('Confidence')
plt.ylabel('F1')
plt.title('F1-Confidence Curve')
plt.grid()
plt.legend()
plt.savefig(os.path.join(SAVE_DIR, "f1_curve.png"))
#plt.show()

# --- Precision-Recall Curve ---
plt.figure(figsize=(12, 8))
for i, class_name in enumerate(class_names):
    precision, recall, _ = precision_recall_curve(y_true[:, i], y_pred[:, i])
    ap = average_precision_score(y_true[:, i], y_pred[:, i])
    plt.plot(recall, precision, label=f'{class_name} {ap:.3f}')

precision_all, recall_all, _ = precision_recall_curve(y_true.ravel(), y_pred.ravel())
average_precision = average_precision_score(y_true, y_pred, average='micro')
plt.plot(recall_all, precision_all, color='blue', linewidth=3,
         label=f'all classes {average_precision:.3f} mAP@0.5')

plt.xlabel('Recall')
plt.ylabel('Precision')
plt.title('Precision-Recall Curve')
plt.grid()
plt.legend()
plt.savefig(os.path.join(SAVE_DIR, "precision_recall_curve.png"))
#plt.show()