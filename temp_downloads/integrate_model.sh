#!/bin/bash

# Script to help integrate the converted model into the Flutter app

# Check if the TFLite model exists
if [ ! -f "orange_model.tflite" ]; then
    echo "Error: orange_model.tflite not found!"
    echo "Please run the Python conversion script first."
    exit 1
fi

# Create backup of existing model
echo "Creating backup of existing model..."
if [ -f "../assets/ml_models/orange_model.tflite" ]; then
    cp "../assets/ml_models/orange_model.tflite" "../assets/ml_models/orange_model.tflite.bak"
    echo "Backup created at assets/ml_models/orange_model.tflite.bak"
fi

# Copy the new model to the assets directory
echo "Copying new model to assets directory..."
cp "orange_model.tflite" "../assets/ml_models/orange_model.tflite"

# Check if copy was successful
if [ $? -eq 0 ]; then
    echo "Model successfully integrated!"
    echo "New model size: $(du -h ../assets/ml_models/orange_model.tflite | cut -f1)"
    echo ""
    echo "Next steps:"
    echo "1. Verify the labels in assets/ml_models/orange_labels.txt match the model"
    echo "2. Run the app to test the new model"
    echo "3. If issues occur, restore the backup with: cp ../assets/ml_models/orange_model.tflite.bak ../assets/ml_models/orange_model.tflite"
else
    echo "Error copying the model. Please check file permissions."
fi

echo ""
echo "Done!" 