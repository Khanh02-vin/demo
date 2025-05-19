import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:go_router/go_router.dart';
import '../providers/history_provider.dart';

class ColorDetectorScreen extends ConsumerStatefulWidget {
  const ColorDetectorScreen({super.key});

  @override
  ConsumerState<ColorDetectorScreen> createState() => _ColorDetectorScreenState();
}

class _ColorDetectorScreenState extends ConsumerState<ColorDetectorScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  String _status = 'Ready to test images';
  Map<String, dynamic>? _analysisResult;
  bool _showResults = false;
  bool _savingToHistory = false;
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Color-based orange detection
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
  
  // Analyze image for quality issues
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

  Future<void> _processImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _status = source == ImageSource.gallery ? 'Selecting image...' : 'Opening camera...';
        _showResults = false;
      });
      
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        setState(() {
          _isLoading = false;
          _status = 'Ready to test images';
        });
        return;
      }
      
      final File imageFile = File(image.path);
      setState(() {
        _selectedImage = imageFile;
        _status = 'Analyzing image...';
      });
      
      // Perform analysis
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
      qualityScore = qualityScore.clamp(0.0, 1.0);
      
      // Determine result
      String resultLabel;
      Color resultColor;
      IconData resultIcon;
      
      if (!isLikelyOrange) {
        resultLabel = 'Not an Orange';
        resultColor = Colors.grey;
        resultIcon = Icons.help_outline;
      } else if (qualityAnalysis['hasMold'] && qualityAnalysis['moldConfidence'] > 0.3) {
        resultLabel = 'Moldy';
        resultColor = Colors.red.shade800;
        resultIcon = Icons.warning_amber_rounded;
      } else if (qualityAnalysis['hasDarkSpots'] && qualityAnalysis['darkSpotsConfidence'] > 0.4) {
        resultLabel = 'Rotten';
        resultColor = Colors.red;
        resultIcon = Icons.sentiment_very_dissatisfied;
      } else if (qualityAnalysis['surfaceIrregularities'] > 0.4) {
        resultLabel = 'Surface Damaged';
        resultColor = Colors.orange;
        resultIcon = Icons.offline_bolt_outlined;
      } else if (qualityScore < 0.7) {
        resultLabel = 'Fair Quality';
        resultColor = Colors.amber;
        resultIcon = Icons.sentiment_neutral;
      } else {
        resultLabel = 'Good Quality';
        resultColor = Colors.green;
        resultIcon = Icons.check_circle;
      }
      
      // Store results
      setState(() {
        _analysisResult = {
          'isOrange': isLikelyOrange,
          'label': resultLabel,
          'color': resultColor,
          'icon': resultIcon,
          'qualityScore': qualityScore,
          'hasMold': qualityAnalysis['hasMold'],
          'moldConfidence': qualityAnalysis['moldConfidence'],
          'hasDarkSpots': qualityAnalysis['hasDarkSpots'],
          'darkSpotsConfidence': qualityAnalysis['darkSpotsConfidence'],
          'colorConsistency': qualityAnalysis['colorConsistency'],
          'surfaceIrregularities': qualityAnalysis['surfaceIrregularities'],
          'processingTime': processingTime,
        };
        _isLoading = false;
        _status = 'Ready to test images';
        _showResults = true;
        _savingToHistory = true;
      });
      
      _animationController.reset();
      _animationController.forward();
      
      // Save to history
      await _saveToHistory(
        imageFile.path,
        isLikelyOrange,
        resultLabel,
        resultColor,
        qualityScore,
        {
          'colorConsistency': qualityAnalysis['colorConsistency'],
          'surfaceIrregularities': qualityAnalysis['surfaceIrregularities'],
          'moldConfidence': qualityAnalysis['moldConfidence'],
          'darkSpotsConfidence': qualityAnalysis['darkSpotsConfidence'],
        },
      );
      
      setState(() {
        _savingToHistory = false;
      });
      
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }
  
  Future<void> _saveToHistory(
    String imagePath,
    bool isOrange,
    String result,
    Color resultColor,
    double qualityScore,
    Map<String, dynamic> detailedMetrics,
  ) async {
    try {
      final historyService = ref.read(historyServiceProvider);
      await historyService.saveHistoryItem(
        imagePath,
        isOrange,
        result,
        resultColor,
        qualityScore,
        detailedMetrics,
      );
      
      // Refresh the history provider
      refreshHistory(ref);
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Orange Color Detector'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.orange.shade800,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _savingToHistory ? 'Saving to history...' : _status,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _selectedImage == null
                  ? _buildInitialScreen()
                  : _buildAnalysisScreen(),
            ),
            
            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _savingToHistory ? null : () => _processImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || _savingToHistory ? null : () => _processImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInitialScreen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF2A2A2A), const Color(0xFF121212)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade800.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_enhance,
              size: 80,
              color: Colors.orange.shade500,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Orange Quality Detector',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          const Text(
            'Take a photo or select an image of an orange to analyze its quality',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 40),
          
          // Instruction steps
          _buildInstructionStep(1, 'Select an image from gallery or take a photo'),
          const SizedBox(height: 12),
          _buildInstructionStep(2, 'Wait for analysis to complete'),
          const SizedBox(height: 12),
          _buildInstructionStep(3, 'View the quality assessment results'),
        ],
      ),
    );
  }
  
  Widget _buildInstructionStep(int number, String text) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnalysisScreen() {
    return Container(
      color: const Color(0xFF121212),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Results section
            if (_isLoading || _savingToHistory)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _savingToHistory ? 'Saving to history...' : 'Analyzing image...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              
            if (_showResults && _analysisResult != null && !_savingToHistory)
              FadeTransition(
                opacity: _animation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main result card
                    Card(
                      elevation: 4,
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              _analysisResult!['icon'] as IconData,
                              size: 60,
                              color: _analysisResult!['color'] as Color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _analysisResult!['label'] as String,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _analysisResult!['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _analysisResult!['isOrange'] 
                                  ? 'This appears to be an orange'
                                  : 'This does not appear to be an orange',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildQualityBar(
                              _analysisResult!['qualityScore'] as double,
                              _analysisResult!['color'] as Color,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Detailed metrics
                    const Text(
                      'Detailed Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Metrics cards
                    _buildMetricCard(
                      'Color Consistency', 
                      _analysisResult!['colorConsistency'] as double,
                      Icons.color_lens_outlined,
                      Colors.blue,
                      'Higher is better',
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildMetricCard(
                      'Surface Quality', 
                      1.0 - (_analysisResult!['surfaceIrregularities'] as double),
                      Icons.layers_outlined,
                      Colors.teal,
                      'Higher is better',
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildRiskCard(
                      'Mold Risk', 
                      _analysisResult!['moldConfidence'] as double,
                      Icons.bug_report_outlined,
                      Colors.purple,
                      'Lower is better',
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildRiskCard(
                      'Rot Risk', 
                      _analysisResult!['darkSpotsConfidence'] as double,
                      Icons.warning_amber_outlined,
                      Colors.deepOrange,
                      'Lower is better',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Processing time
                    Center(
                      child: Text(
                        'Analysis took ${_analysisResult!['processingTime']} ms',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQualityBar(double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quality Score',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Progress
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 10,
              width: MediaQuery.of(context).size.width * 0.7 * value,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, double value, IconData icon, Color color, String note) {
    return Card(
      elevation: 2,
      color: const Color(0xFF252525),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getMetricColor(value).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getMetricColor(value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRiskCard(String title, double value, IconData icon, Color color, String note) {
    return Card(
      elevation: 2,
      color: const Color(0xFF252525),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRiskColor(value).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getRiskColor(value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getMetricColor(double value) {
    if (value >= 0.8) return Colors.green.shade400;
    if (value >= 0.6) return Colors.lime.shade400;
    if (value >= 0.4) return Colors.amber.shade400;
    if (value >= 0.2) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
  
  Color _getRiskColor(double value) {
    if (value <= 0.2) return Colors.green.shade400;
    if (value <= 0.4) return Colors.lime.shade400;
    if (value <= 0.6) return Colors.amber.shade400;
    if (value <= 0.8) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
} 