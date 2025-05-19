import tensorflow as tf
import os
MODEL_PATH = '../assets/ml_models/orange_classifier_cnn_improved.h5'
OUTPUT_PATH = '../assets/ml_models/orange_model.tflite'
model = tf.keras.models.load_model(MODEL_PATH)
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
with open(OUTPUT_PATH, "wb") as f:
    f.write(tflite_model)
print("Conversion completed!")
