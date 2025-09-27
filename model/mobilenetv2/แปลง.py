import tensorflow as tf

# โหลดโมเดล Keras
model = tf.keras.models.load_model('C:/Users/Acer/Desktop/Project/mobilenetv2/ผลลัพธ์/train3/mobilenetv2_age_classifier_best.keras')

# สร้างตัวแปลง TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# แปลงเป็น TFLite
tflite_model = converter.convert()

# บันทึกไฟล์
with open('mobilenetv2.tflite', 'wb') as f:
    f.write(tflite_model)

print("MobileNetV2 TFLite conversion done!")