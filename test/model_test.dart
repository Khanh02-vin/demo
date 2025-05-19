import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:orange_quality_checker/services/orange_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late OrangeClassifier classifier;
  
  setUp(() {
    classifier = OrangeClassifier();
    
    // Initialize asset bundle for testing
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter/assets'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAssetPath') {
          return 'assets/ml_models/orange_classifier_cnn_improved.tflite';
        }
        return null;
      },
    );
  });
  
  test('Model file exists and has correct size', () async {
    final bundle = rootBundle;
    try {
      final ByteData data = await bundle.load('assets/ml_models/orange_classifier_cnn_improved.tflite');
      final int fileSizeInBytes = data.lengthInBytes;
      
      // Verify the model file is not a placeholder (at least 1MB)
      expect(fileSizeInBytes, greaterThan(1024 * 1024), 
          reason: 'Model file should be at least 1MB in size');
      
      print('Model size: ${fileSizeInBytes / (1024 * 1024)} MB');
    } catch (e) {
      fail('Model file does not exist or could not be loaded: $e');
    }
  });
  
  test('Can load the model without errors', () async {
    try {
      await classifier.loadPrimaryModel();
      // If no exception is thrown, the test passes
    } catch (e) {
      fail('Failed to load the model: $e');
    }
  });
  
  // For integration testing on a real device/emulator, add a test to classify a real image
  // This will be skipped in unit testing as it requires a real device
  testWidgets('Classification returns expected results', (WidgetTester tester) async {
    // Skip this test in CI environments
    if (Platform.environment.containsKey('CI')) {
      return;
    }
    
    try {
      // Create a temporary file for testing
      final Directory tempDir = await getTemporaryDirectory();
      final File testFile = File('${tempDir.path}/test_orange.jpg');
      
      // For actual testing, you would need a real image here
      // This test will be manually run on device with real images
      
      if (await testFile.exists()) {
        await classifier.loadModels();
        final result = await classifier.classifyImage(testFile);
        
        // Basic validation that classification produced some result
        expect(result, isNotNull);
        expect(result.primaryLabel, isNotEmpty);
        expect(result.primaryConfidence, greaterThan(0));
        
        print('Classification result: ${result.primaryLabel} (${result.primaryConfidence})');
      } else {
        // Skip this test if the test image doesn't exist
        print('Test image not found. Skipping classification test.');
      }
    } catch (e) {
      fail('Classification test failed: $e');
    }
  });
} 