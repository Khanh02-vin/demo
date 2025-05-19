# Model Conversion and Integration Instructions

## Prerequisites
- Python 3.7 or higher
- TensorFlow 2.x (`pip install tensorflow`)

## Steps to Convert and Integrate the Model

### 1. Convert the H5 Model to TFLite

1. Download the `orange_classifier_cnn_improved.h5` file from Kaggle
2. Place the downloaded file in this directory
3. Run the conversion script:
   ```
   python convert_model.py
   ```
4. The script will create `orange_model.tflite` in the same directory

### 2. Update the Flutter App

1. Copy the generated `orange_model.tflite` file to:
   ```
   assets/ml_models/orange_model.tflite
   ```

2. Verify the label file matches the classes in the new model:
   - Check if the Kaggle model uses the same labels as your current `orange_labels.txt`
   - If not, update `assets/ml_models/orange_labels.txt` with the correct labels

3. Run the app to test the new model:
   ```
   flutter run
   ```

## Troubleshooting

If you encounter issues:

1. **Memory errors during conversion**: 
   - Try running on a machine with more RAM
   - Or modify the script to use TensorFlow's optimization flags

2. **TFLite model size issues**:
   - The script includes optimization flags, but you can adjust these for more compression

3. **Incompatible labels**:
   - Make sure the labels file matches exactly what the model was trained on 