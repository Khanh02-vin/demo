import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../services/orange_classifier.dart';

class ModelTester {
  static Future<String> testModelLoading() async {
    String result = "";
    
    try {
      // First, check if the asset files exist
      result += "Testing ML model files...\n";
      
      // Check for the model file
      try {
        final modelAsset = await rootBundle.load('assets/ml_models/orange_classifier_cnn_improved.tflite');
        final sizeInMB = modelAsset.lengthInBytes / (1024 * 1024);
        result += "✓ Model file found (${sizeInMB.toStringAsFixed(2)} MB)\n";
        
        if (modelAsset.lengthInBytes < 1000000) {
          result += "⚠️ Warning: Model file is smaller than expected (< 1 MB), might be incomplete\n";
        }
      } catch (e) {
        result += "✗ Model file not found: $e\n";
      }
      
      // Check for the labels file
      try {
        final labelsData = await rootBundle.loadString('assets/ml_models/orange_labels.txt');
        final labels = labelsData.split('\n');
        result += "✓ Labels file loaded successfully: ${labels.length} labels found\n";
        result += "Labels: ${labels.join(', ')}\n";
      } catch (e) {
        result += "✗ Error loading labels: $e\n";
      }
      
      // Try to load and initialize the model using TFLite
      try {
        result += "\nTesting model initialization...\n";
        final interpreter = await Interpreter.fromAsset('assets/ml_models/orange_classifier_cnn_improved.tflite');
        
        // Get model input and output shapes
        final inputShape = interpreter.getInputTensor(0).shape;
        final outputShape = interpreter.getOutputTensor(0).shape;
        
        result += "✓ Model initialized successfully\n";
        result += "Model input shape: ${inputShape.join('x')}\n";
        result += "Model output shape: ${outputShape.join('x')}\n";
        
        // Clean up
        interpreter.close();
      } catch (e) {
        result += "✗ Error initializing model: $e\n";
      }
      
      // Try to initialize the Orange Classifier
      try {
        result += "\nTesting OrangeClassifier service...\n";
        final classifier = OrangeClassifier();
        await classifier.loadPrimaryModel();
        result += "✓ OrangeClassifier loaded models successfully\n";
        
        // Clean up
        classifier.dispose();
      } catch (e) {
        result += "✗ Error initializing OrangeClassifier: $e\n";
      }
      
      // Platform-specific tests for TensorFlow
      if (Platform.isIOS || Platform.isAndroid) {
        result += "\nPlatform supports TensorFlow Lite - to test fully, run the app on a real device\n";
      } else {
        result += "\nPlatform ${Platform.operatingSystem} doesn't support direct TensorFlow Lite testing\n";
      }
    } catch (e) {
      result += "✗ Error testing model: $e\n";
    }
    
    return result;
  }
} 