import tensorflow as tf
import os

# Path to the downloaded H5 model
# Change this to the actual path where you downloaded the model
MODEL_PATH = 'orange_classifier_cnn_improved.h5'

# Path for the output TFLite model
OUTPUT_PATH = 'orange_model.tflite'

def convert_h5_to_tflite():
    # Load the H5 model
    print(f"Loading model from {MODEL_PATH}...")
    model = tf.keras.models.load_model(MODEL_PATH)
    
    # Convert the model to TFLite format
    print("Converting model to TFLite format...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Apply optimizations
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Convert the model
    tflite_model = converter.convert()
    
    # Save the TFLite model
    with open(OUTPUT_PATH, 'wb') as f:
        f.write(tflite_model)
    
    print(f"Model converted and saved to {OUTPUT_PATH}")
    print(f"Original model size: {os.path.getsize(MODEL_PATH) / (1024 * 1024):.2f} MB")
    print(f"TFLite model size: {os.path.getsize(OUTPUT_PATH) / (1024 * 1024):.2f} MB")

if __name__ == "__main__":
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model file {MODEL_PATH} not found.")
        print("Please download the model and place it in the same directory as this script.")
        exit(1)
    
    convert_h5_to_tflite()
    print("Conversion completed successfully.") 