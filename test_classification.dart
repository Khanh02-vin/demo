import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:orange_quality_checker/services/orange_classifier.dart';
import 'package:orange_quality_checker/models/classification_result.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

// A script to test orange detection based on color analysis
// To run: flutter run -d <device_id> test_classification.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MaterialApp(
    home: ColorBasedTestApp(),
  ));
}

class ColorBasedTestApp extends StatefulWidget {
  const ColorBasedTestApp({super.key});

  @override
  State<ColorBasedTestApp> createState() => _ColorBasedTestAppState();
}

class _ColorBasedTestAppState extends State<ColorBasedTestApp> {
  final OrangeClassifier _classifier = OrangeClassifier();
  final List<String> _log = [];
  bool _isLoading = false;
  String _status = 'Ready to test images';
  
  // For image selection
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  void _addLog(String message) {
    setState(() {
      _log.add(message);
    });
  }
  
  // Color-based orange detection (simplified version of the classifier's method)
  Future<bool> isLikelyOrangeByColor(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) return false;
      
      // Sample pixels from the image to check for orange color
      int orangePixels = 0;
      int totalSamples = 0;
      
      // Sample grid of pixels with a reasonable step size
      final int sampleStep = max(2, min(8, image.width ~/ 50));
      
      for (int y = 0; y < image.height; y += sampleStep) {
        for (int x = 0; x < image.width; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          
          // Convert RGB to HSV for better color analysis
          final double r = pixel.r / 255.0;
          final double g = pixel.g / 255.0;
          final double b = pixel.b / 255.0;
          final hsv = _rgbToHsv(r, g, b);
          
          // Enhanced detection using HSV space
          bool isOrangeHue = (hsv[0] >= 0.03 && hsv[0] <= 0.17); // 10-60 degrees
          
          if (isOrangeHue && 
              hsv[1] > 0.3 && // Must be somewhat saturated
              hsv[2] > 0.2 && // Not too dark
              pixel.r > pixel.g && pixel.g > pixel.b) { // RGB relationship
            orangePixels++;
          }
          // Also check using traditional RGB method as fallback
          else if ((pixel.r > 120 && // Red component is significant
               pixel.g > 50 && pixel.g < 220 && // Medium green
               pixel.b < 100 && // Low blue
               pixel.r > pixel.g * 1.1 && // Red notably higher than green
               pixel.g > pixel.b * 1.2) || // Green notably higher than blue
              // Additional check for brighter oranges
              (pixel.r > 180 && pixel.g > 80 && pixel.g < 170 && pixel.b < 80)) {
            orangePixels++;
          }
          totalSamples++;
        }
      }
      
      // Calculate the ratio of orange pixels
      final orangeRatio = orangePixels / totalSamples;
      
      // Return true if enough orange pixels are found
      return orangeRatio > 0.12;
    } catch (e) {
      debugPrint('Error in color detection: $e');
      return false;
    }
  }
  
  // Convert RGB to HSV color space
  List<double> _rgbToHsv(double r, double g, double b) {
    double max = [r, g, b].reduce((curr, next) => curr > next ? curr : next);
    double min = [r, g, b].reduce((curr, next) => curr < next ? curr : next);
    double h = 0, s = 0, v = max;
    
    double d = max - min;
    s = max == 0 ? 0 : d / max;
    
    if (max == min) {
      h = 0; // achromatic
    } else {
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else if (max == b) {
        h = (r - g) / d + 4;
      }
      h /= 6;
    }
    
    return [h, s, v];
  }
  
  // Analyze image for quality issues (simplified)
  Future<Map<String, dynamic>> analyzeImageQuality(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return {
          'hasMold': false,
          'hasDarkSpots': false,
          'moldConfidence': 0.0,
          'darkSpotsConfidence': 0.0,
          'texturalAnomaly': false,
          'colorConsistency': 1.0,
          'surfaceIrregularities': 0.0
        };
      }
      
      // Simplified analysis (real detection would be more complex)
      // This is just a basic detection to avoid using the private methods
      
      int moldPixels = 0;
      int darkSpotsPixels = 0;
      int totalPixels = 0;
      List<double> hueSamples = [];
      
      // Sample grid of pixels
      const int sampleStep = 8;
      
      for (int y = 0; y < image.height; y += sampleStep) {
        for (int x = 0; x < image.width; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          totalPixels++;
          
          // Convert RGB to HSV for better color analysis
          final double r = pixel.r / 255.0;
          final double g = pixel.g / 255.0;
          final double b = pixel.b / 255.0;
          
          final hsv = _rgbToHsv(r, g, b);
          final double hue = hsv[0];
          final double saturation = hsv[1];
          final double value = hsv[2];
          
          // Add to hue samples for consistency calculation
          if (saturation > 0.2 && value > 0.2) {
            hueSamples.add(hue);
          }
          
          // Simple mold detection (blue-green colors or white spots)
          if ((hue > 110/360 && hue < 200/360 && saturation > 0.15 && value > 0.3) ||
              (saturation < 0.2 && value > 0.8 && r > 200 && g > 200 && b > 200)) {
            moldPixels++;
          }
          
          // Simple dark spots detection
          if (value < 0.15) {
            darkSpotsPixels++;
          }
        }
      }
      
      // Calculate ratios
      double moldRatio = moldPixels / totalPixels;
      double darkSpotsRatio = darkSpotsPixels / totalPixels;
      
      // Calculate color consistency
      double colorConsistency = 1.0;
      if (hueSamples.length > 10) {
        double avgHue = hueSamples.reduce((a, b) => a + b) / hueSamples.length;
        double sumDiff = 0;
        for (final hue in hueSamples) {
          double diff = (hue - avgHue).abs();
          if (diff > 0.5) diff = 1 - diff; // Handle circular nature of hue
          sumDiff += diff;
        }
        colorConsistency = 1.0 - (sumDiff / hueSamples.length * 4);
        colorConsistency = colorConsistency.clamp(0.0, 1.0);
      }
      
      return {
        'hasMold': moldRatio > 0.03,
        'hasDarkSpots': darkSpotsRatio > 0.05,
        'moldConfidence': (moldRatio * 10).clamp(0.0, 1.0),
        'darkSpotsConfidence': (darkSpotsRatio * 5).clamp(0.0, 1.0),
        'texturalAnomaly': moldRatio > 0.02 || darkSpotsRatio > 0.04,
        'colorConsistency': colorConsistency,
        'surfaceIrregularities': ((1.0 - colorConsistency) * 0.5).clamp(0.0, 1.0)
      };
    } catch (e) {
      debugPrint('Error in quality analysis: $e');
      return {
        'hasMold': false,
        'hasDarkSpots': false,
        'moldConfidence': 0.0,
        'darkSpotsConfidence': 0.0,
        'texturalAnomaly': false,
        'colorConsistency': 1.0,
        'surfaceIrregularities': 0.0
      };
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Selecting image...';
      });
      
      // Pick an image
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        _addLog('No image selected');
        setState(() {
          _isLoading = false;
          _status = 'Ready to test';
        });
        return;
      }
      
      // Convert to File
      final File imageFile = File(image.path);
      setState(() {
        _selectedImage = imageFile;
        _status = 'Analyzing image...';
      });
      
      // Perform color analysis
      final startTime = DateTime.now();
      final isLikelyOrange = await isLikelyOrangeByColor(imageFile);
      final qualityAnalysis = await analyzeImageQuality(imageFile);
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      
      // Calculate quality score based on analysis
      double qualityScore = 1.0;
      if (qualityAnalysis['hasMold']) {
        qualityScore -= qualityAnalysis['moldConfidence'] * 0.8;
      }
      if (qualityAnalysis['hasDarkSpots']) {
        qualityScore -= qualityAnalysis['darkSpotsConfidence'] * 0.6;
      }
      if (qualityAnalysis['texturalAnomaly']) {
        qualityScore -= 0.3;
      }
      if (qualityAnalysis['surfaceIrregularities'] > 0.1) {
        qualityScore -= qualityAnalysis['surfaceIrregularities'] * 0.5;
      }
      qualityScore *= qualityAnalysis['colorConsistency'];
      qualityScore = qualityScore < 0 ? 0 : (qualityScore > 1 ? 1 : qualityScore);
      
      // Determine result
      String resultLabel;
      if (!isLikelyOrange) {
        resultLabel = 'Not an Orange';
      } else if (qualityAnalysis['hasMold'] && qualityAnalysis['moldConfidence'] > 0.3) {
        resultLabel = 'Moldy';
      } else if (qualityAnalysis['hasDarkSpots'] && qualityAnalysis['darkSpotsConfidence'] > 0.4) {
        resultLabel = 'Rotten';
      } else if (qualityAnalysis['surfaceIrregularities'] > 0.4) {
        resultLabel = 'Surface Damaged';
      } else if (qualityScore < 0.7) {
        resultLabel = 'Fair Quality';
      } else {
        resultLabel = 'Good Quality';
      }
      
      _addLog('Image analysis complete:');
      _addLog('Is likely an orange: ${isLikelyOrange ? "YES" : "NO"}');
      _addLog('Classification: $resultLabel');
      _addLog('Quality score: ${(qualityScore * 100).toStringAsFixed(1)}%');
      _addLog('Has mold: ${qualityAnalysis['hasMold']} (${(qualityAnalysis['moldConfidence'] * 100).toStringAsFixed(1)}%)');
      _addLog('Has dark spots: ${qualityAnalysis['hasDarkSpots']} (${(qualityAnalysis['darkSpotsConfidence'] * 100).toStringAsFixed(1)}%)');
      _addLog('Color consistency: ${(qualityAnalysis['colorConsistency'] * 100).toStringAsFixed(1)}%');
      _addLog('Surface irregularities: ${(qualityAnalysis['surfaceIrregularities'] * 100).toStringAsFixed(1)}%');
      _addLog('Processing time: $processingTime ms');
      _addLog('--------------------');
      
    } catch (e) {
      _addLog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _status = 'Ready to test';
      });
    }
  }

  Future<void> _pickCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Opening camera...';
      });
      
      // Take a photo
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        _addLog('No photo taken');
        setState(() {
          _isLoading = false;
          _status = 'Ready to test';
        });
        return;
      }
      
      // Convert to File
      final File imageFile = File(image.path);
      setState(() {
        _selectedImage = imageFile;
        _status = 'Analyzing image...';
      });
      
      // Perform color analysis
      final startTime = DateTime.now();
      final isLikelyOrange = await isLikelyOrangeByColor(imageFile);
      final qualityAnalysis = await analyzeImageQuality(imageFile);
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;
      
      // Calculate quality score based on analysis
      double qualityScore = 1.0;
      if (qualityAnalysis['hasMold']) {
        qualityScore -= qualityAnalysis['moldConfidence'] * 0.8;
      }
      if (qualityAnalysis['hasDarkSpots']) {
        qualityScore -= qualityAnalysis['darkSpotsConfidence'] * 0.6;
      }
      if (qualityAnalysis['texturalAnomaly']) {
        qualityScore -= 0.3;
      }
      if (qualityAnalysis['surfaceIrregularities'] > 0.1) {
        qualityScore -= qualityAnalysis['surfaceIrregularities'] * 0.5;
      }
      qualityScore *= qualityAnalysis['colorConsistency'];
      qualityScore = qualityScore < 0 ? 0 : (qualityScore > 1 ? 1 : qualityScore);
      
      // Determine result
      String resultLabel;
      if (!isLikelyOrange) {
        resultLabel = 'Not an Orange';
      } else if (qualityAnalysis['hasMold'] && qualityAnalysis['moldConfidence'] > 0.3) {
        resultLabel = 'Moldy';
      } else if (qualityAnalysis['hasDarkSpots'] && qualityAnalysis['darkSpotsConfidence'] > 0.4) {
        resultLabel = 'Rotten';
      } else if (qualityAnalysis['surfaceIrregularities'] > 0.4) {
        resultLabel = 'Surface Damaged';
      } else if (qualityScore < 0.7) {
        resultLabel = 'Fair Quality';
      } else {
        resultLabel = 'Good Quality';
      }
      
      _addLog('Image analysis complete:');
      _addLog('Is likely an orange: ${isLikelyOrange ? "YES" : "NO"}');
      _addLog('Classification: $resultLabel');
      _addLog('Quality score: ${(qualityScore * 100).toStringAsFixed(1)}%');
      _addLog('Has mold: ${qualityAnalysis['hasMold']} (${(qualityAnalysis['moldConfidence'] * 100).toStringAsFixed(1)}%)');
      _addLog('Has dark spots: ${qualityAnalysis['hasDarkSpots']} (${(qualityAnalysis['darkSpotsConfidence'] * 100).toStringAsFixed(1)}%)');
      _addLog('Color consistency: ${(qualityAnalysis['colorConsistency'] * 100).toStringAsFixed(1)}%');
      _addLog('Surface irregularities: ${(qualityAnalysis['surfaceIrregularities'] * 100).toStringAsFixed(1)}%');
      _addLog('Processing time: $processingTime ms');
      _addLog('--------------------');
      
    } catch (e) {
      _addLog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _status = 'Ready to test';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orange Color Detector Test'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (!_isLoading) Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickAndAnalyzeImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select from Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (_selectedImage != null)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length,
              itemBuilder: (context, index) {
                final message = _log[index];
                TextStyle style = const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                );
                
                if (message.contains('Is likely an orange: YES')) {
                  style = style.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  );
                } else if (message.contains('Is likely an orange: NO')) {
                  style = style.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  );
                } else if (message.contains('Good Quality')) {
                  style = style.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  );
                } else if (message.contains('Bad') || message.contains('Moldy') || message.contains('Rotten')) {
                  style = style.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(message, style: style),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
} 