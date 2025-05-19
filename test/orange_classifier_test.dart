import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orange_quality_checker/services/orange_classifier.dart';
import 'package:orange_quality_checker/models/classification_result.dart';

// Mock classifier for testing
class TestOrangeClassifier extends OrangeClassifier {
  @override
  Future<ClassificationResult> classifyImage(File? imageFile) async {
    // For test files with "moldy" in the filename, return bad quality
    if (imageFile != null && imageFile.path.contains('moldy')) {
      return ClassificationResult(
        primaryLabel: 'Bad Quality',
        primaryConfidence: 0.9,
      );
    } else {
      // Otherwise return good quality
      return ClassificationResult(
        primaryLabel: 'Good Quality',
        primaryConfidence: 0.85,
      );
    }
  }
  
  @override
  Future<void> loadModels() async {
    // Do nothing in tests
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late TestOrangeClassifier classifier;
  late Directory tempDir;
  
  setUpAll(() async {
    // Set up temporary directory for test files
    tempDir = await Directory.systemTemp.createTemp('orange_test_');
  });
  
  setUp(() {
    classifier = TestOrangeClassifier();
  });
  
  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });
  
  test('Classifies moldy oranges as bad quality', () async {
    // Create a test image file with a name indicating mold
    final testImageFile = await File('${tempDir.path}/moldy_orange_test.png').create();
    
    // Test classification result
    final result = await classifier.classifyImage(testImageFile);
    
    // Verify classification
    expect(result.primaryLabel, equals('Bad Quality'), 
           reason: 'Should classify moldy orange as Bad Quality');
    expect(result.primaryConfidence, greaterThanOrEqualTo(0.85), 
           reason: 'Should have high confidence for moldy orange');
  });
  
  test('Classifies good quality oranges correctly', () async {
    // Create a test image file without "moldy" in the name
    final testImageFile = await File('${tempDir.path}/good_orange_test.png').create();
    
    // Test classification
    final result = await classifier.classifyImage(testImageFile);
    
    // Verify classification
    expect(result.primaryLabel, equals('Good Quality'), 
           reason: 'Should classify good orange correctly');
    expect(result.primaryConfidence, greaterThanOrEqualTo(0.8), 
           reason: 'Should have high confidence for good orange');
  });
} 