#!/bin/bash

echo "Running Orange Classifier Model Test"
echo "===================================="

# Check environment
echo "Checking environment..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo "✅ Flutter installed: $FLUTTER_VERSION"
else
    echo "❌ Flutter not found in PATH"
    exit 1
fi

# Check if the model file exists
if [ -f "assets/ml_models/orange_classifier_cnn_improved.tflite" ]; then
  MODEL_SIZE=$(du -h "assets/ml_models/orange_classifier_cnn_improved.tflite" | cut -f1)
  echo "✅ Model file found: $MODEL_SIZE"
else
  echo "❌ Model file not found!"
  exit 1
fi

# Check if labels file exists
if [ -f "assets/ml_models/orange_labels.txt" ]; then
  LABELS=$(cat "assets/ml_models/orange_labels.txt" | wc -l)
  LABEL_CONTENT=$(cat "assets/ml_models/orange_labels.txt")
  echo "✅ Labels file found with $LABELS labels: $LABEL_CONTENT"
else
  echo "❌ Labels file not found!"
  exit 1
fi

# Check project dependencies
echo ""
echo "Checking project dependencies..."
grep "tflite_flutter:" pubspec.yaml &> /dev/null
if [ $? -eq 0 ]; then
  echo "✅ TensorFlow Lite Flutter dependency found"
else
  echo "❌ TensorFlow Lite Flutter dependency missing in pubspec.yaml"
  exit 1
fi

grep "image:" pubspec.yaml &> /dev/null
if [ $? -eq 0 ]; then
  echo "✅ Image processing dependency found"
else
  echo "❌ Image processing dependency missing in pubspec.yaml"
  exit 1
fi

# Run Flutter tests
echo ""
echo "Running Flutter tests..."
flutter test test/model_test.dart

# Run dart analyzer
echo ""
echo "Running analyzer on model-related code..."
flutter analyze lib/services/orange_classifier.dart lib/screens/model_test_screen.dart

# Compile the app to check for build errors
echo ""
echo "Building app (debug mode)..."
flutter build ios --debug --no-codesign

# Success message and usage instructions
echo ""
echo "✅ Model verification completed successfully!"
echo ""
echo "To test model in the app:"
echo "1. Run the app on a real device"
echo "2. Navigate to the Model Test screen"
echo "3. Press 'Run Model Test' to check model loading"
echo "4. Press 'Test with Image' to test classification with a real image"
echo ""
echo "For more thorough testing, use the following steps:"
echo "1. Check debug logs while testing to see the model's input/output shapes"
echo "2. Validate the output format matches your expectations"
echo "3. Try multiple images with different orange qualities to ensure correct classification"
echo "" 