import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:go_router/go_router.dart';
import '../providers/history_provider.dart';
import '../providers/app_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
    
    // Restore image if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedImagePath = ref.read(selectedImageProvider);
      if (savedImagePath != null) {
        setState(() {
          _selectedImage = File(savedImagePath);
        });
        
        // Restore analysis results if available
        final savedResults = ref.read(analysisResultProvider);
        final shouldShowResults = ref.read(showResultsProvider);
        
        if (savedResults != null && shouldShowResults) {
          setState(() {
            _analysisResult = savedResults;
            _showResults = shouldShowResults;
          });
          _animationController.forward(from: 0.0);
        }
      }
    });
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
      
      // Clear previous results
      ref.read(analysisResultProvider.notifier).state = null;
      ref.read(showResultsProvider.notifier).state = false;
      
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
      
      // Save to provider for persistence
      ref.read(selectedImageProvider.notifier).state = image.path;
      
      // Check if this is an orange by color first
      final isOrange = await isLikelyOrangeByColor(imageFile);
      
      if (!isOrange) {
        final results = {
          'isOrange': false,
          'quality': 'unknown',
          'colorConsistency': 0.0,
          'surfaceIrregularities': 0.0,
          'recommendation': 'This does not appear to be an orange.'
        };
        
        setState(() {
          _isLoading = false;
          _status = 'Not an orange';
          _analysisResult = results;
          _showResults = true;
        });
        
        // Save results to provider
        ref.read(analysisResultProvider.notifier).state = results;
        ref.read(showResultsProvider.notifier).state = true;
        
        _animationController.forward(from: 0.0);
        return;
      }
      
      // If it is an orange, analyze its quality
      final qualityResults = await analyzeImageQuality(imageFile);
      
      // Determine overall quality based on analysis
      String quality;
      String recommendation;
      
      if (qualityResults['hasMold'] == true) {
        quality = 'Poor - Mold Detected';
        recommendation = 'This orange shows signs of mold and should not be consumed.';
      } else if (qualityResults['hasDarkSpots'] == true) {
        quality = 'Poor - Dark Spots';
        recommendation = 'This orange has significant dark spots and may have quality issues.';
      } else if (qualityResults['colorConsistency'] < 0.7) {
        quality = 'Fair - Color Inconsistency';
        recommendation = 'This orange has some color variations that may indicate ripeness issues.';
      } else if (qualityResults['surfaceIrregularities'] > 0.3) {
        quality = 'Fair - Surface Issues';
        recommendation = 'This orange has some surface irregularities but should be edible.';
      } else {
        quality = 'Good';
        recommendation = 'This orange appears to be of good quality.';
      }
      
      final results = {
        'isOrange': true,
        'quality': quality,
        'colorConsistency': qualityResults['colorConsistency'],
        'surfaceIrregularities': qualityResults['surfaceIrregularities'],
        'hasMold': qualityResults['hasMold'],
        'hasDarkSpots': qualityResults['hasDarkSpots'],
        'recommendation': recommendation
      };
      
      setState(() {
        _isLoading = false;
        _status = 'Analysis complete';
        _analysisResult = results;
        _showResults = true;
      });
      
      // Save results to provider
      ref.read(analysisResultProvider.notifier).state = results;
      ref.read(showResultsProvider.notifier).state = true;
      
      _animationController.forward(from: 0.0);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }
  
  Future<void> _saveToHistory() async {
    if (_analysisResult == null || _selectedImage == null || _savingToHistory) {
      return;
    }
    
    setState(() {
      _savingToHistory = true;
    });
    
    try {
      final historyService = ref.read(historyServiceProvider);
      
      // Get color based on quality
      final quality = _analysisResult!['quality'] as String;
      Color resultColor;
      
      if (quality.toLowerCase().contains('good')) {
        resultColor = Colors.green;
      } else if (quality.toLowerCase().contains('fair')) {
        resultColor = Colors.orange;
      } else {
        resultColor = Colors.red;
      }
      
      // Calculate quality score
      double qualityScore = 0.0;
      if (_analysisResult!['isOrange'] as bool) {
        qualityScore = (_analysisResult!['colorConsistency'] as double) * 0.6 + 
                      (1.0 - (_analysisResult!['surfaceIrregularities'] as double)) * 0.4;
      }
      
      await historyService.saveHistoryItem(
        _selectedImage!.path,
        _analysisResult!['isOrange'] as bool,
        _analysisResult!['quality'] as String,
        resultColor,
        qualityScore,
        {
          'colorConsistency': _analysisResult!['colorConsistency'],
          'surfaceIrregularities': _analysisResult!['surfaceIrregularities'],
        },
      );
      
      // Refresh history
      refreshHistory(ref);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to history'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingToHistory = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Orange Detector',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Orange Quality Detector',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Take or select a photo of an orange to check its quality',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildImageSection(),
                      const SizedBox(height: 24),
                      if (_showResults && _analysisResult != null)
                        _buildResultsSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: child,
            );
          },
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _selectedImage == null 
                    ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
                    : [Colors.orange.shade800.withOpacity(0.8), Colors.deepOrange.shade600.withOpacity(0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _selectedImage == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _status,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _status,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final result = _analysisResult!;
    final isOrange = result['isOrange'] as bool;
    final quality = result['quality'] as String;
    final recommendation = result['recommendation'] as String;
    
    Color statusColor;
    IconData statusIcon;
    
    if (!isOrange) {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
    } else if (quality.toLowerCase().contains('good')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (quality.toLowerCase().contains('fair')) {
      statusColor = Colors.orange;
      statusIcon = Icons.info;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C2C2E),
              const Color(0xFF1C1C1E),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOrange ? 'Orange Quality: $quality' : 'Not an Orange',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                recommendation,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 20),
              if (isOrange) ...[
                _buildQualityIndicator(
                  label: 'Color Consistency',
                  value: result['colorConsistency'] as double,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildQualityIndicator(
                  label: 'Surface Quality',
                  value: 1.0 - (result['surfaceIrregularities'] as double),
                  color: Colors.purple,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _savingToHistory ? null : _saveToHistory,
                    icon: Icon(
                      _savingToHistory ? Icons.hourglass_empty : Icons.save_alt,
                      color: Colors.white,
                    ),
                    label: Text(
                      _savingToHistory ? 'Saving...' : 'Save to History',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityIndicator({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.8 * value * _animation.value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        color.withOpacity(0.7),
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildActionButton(
              onPressed: _isLoading ? null : () => _processImage(ImageSource.gallery),
              color: Colors.deepPurple,
              icon: Icons.photo_library,
              label: 'Gallery',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              onPressed: _isLoading ? null : () => _processImage(ImageSource.camera),
              color: Colors.deepOrange,
              icon: Icons.camera_alt,
              label: 'Camera',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
    );
  }
} 