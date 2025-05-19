import tensorflow as tf
import os

# Path to the input h5 model and output tflite model
input_model_path = 'assets/ml_models/orange_classifier_cnn_improved.h5'
output_model_path = 'assets/ml_models/orange_model.tflite'

def convert_h5_to_tflite():
    print(f"Loading model from {input_model_path}")
    
    # Load the h5 model
    model = tf.keras.models.load_model(input_model_path)
    
    # Convert the model to TensorFlow Lite format
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Apply optimizations
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Convert the model
    tflite_model = converter.convert()
    
    # Save the model to a file
    with open(output_model_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"Converted model saved to {output_model_path}")
    print(f"Model size: {os.path.getsize(output_model_path) / (1024 * 1024):.2f} MB")

if __name__ == "__main__":
    convert_h5_to_tflite() 