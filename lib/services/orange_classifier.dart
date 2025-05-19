import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import '../models/classification_result.dart';
import '../utils/image_quality_checker.dart';
import 'dart:math';

class OrangeClassifier {
  static const String MODEL_FILE = 'assets/ml_models/orange_classifier_cnn_improved.tflite';
  static const String LABELS_FILE = 'assets/ml_models/orange_labels.txt';
  
  // New fields for fallback model
  static const String FALLBACK_MODEL_FILE = 'assets/ml_models/fallback_model.tflite';
  static const String FALLBACK_LABELS_FILE = 'assets/ml_models/fallback_labels.txt';
  
  // Confidence thresholds - adjusted for real model
  static const double PRIMARY_CONFIDENCE_THRESHOLD = 0.6;
  
  Interpreter? _interpreter;
  Interpreter? _fallbackInterpreter;
  List<String>? _labels;
  List<String>? _fallbackLabels;
  
  // Model parameters - will be updated from actual model
  late int inputSize;
  List<int>? inputShape;
  List<int>? outputShape;
  
  /// Loads both the primary and fallback classification models
  Future<void> loadModels() async {
    await loadPrimaryModel();
    await loadFallbackModel();
  }
  
  /// Loads the primary orange classification model
  Future<void> loadPrimaryModel() async {
    try {
      if (_interpreter == null) {
        debugPrint('Loading model from $MODEL_FILE');
        _interpreter = await Interpreter.fromAsset(MODEL_FILE);
        
        // Get actual model input shape
        inputShape = _interpreter!.getInputTensor(0).shape;
        outputShape = _interpreter!.getOutputTensor(0).shape;
        
        // Update inputSize based on actual model
        if (inputShape != null && inputShape!.length >= 2) {
          // Use the height dimension from the model (usually shape is [1, height, width, channels])
          inputSize = inputShape![1];
          debugPrint('Model input size detected as: $inputSize');
        } else {
          // Fallback to default
          inputSize = 224;
          debugPrint('Using default input size: $inputSize');
        }
        
        _labels = await _loadLabels(LABELS_FILE);
        debugPrint('Orange classifier model loaded. Input shape: $inputShape, Output shape: $outputShape');
        debugPrint('Labels: $_labels');
      }
    } catch (e) {
      debugPrint('Error loading primary model: $e');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }
  
  /// Loads the fallback general classification model
  Future<void> loadFallbackModel() async {
    try {
      // Check if fallback model file exists
      final modelExists = await _checkAssetExists(FALLBACK_MODEL_FILE);
      if (!modelExists) {
        debugPrint('Fallback model not available: $FALLBACK_MODEL_FILE');
        return;
      }
      
      if (_fallbackInterpreter == null) {
        _fallbackInterpreter = await Interpreter.fromAsset(FALLBACK_MODEL_FILE);
        _fallbackLabels = await _loadLabels(FALLBACK_LABELS_FILE);
        debugPrint('Fallback classifier model loaded successfully');
      }
    } catch (e) {
      debugPrint('Error loading fallback model: $e');
      // Don't rethrow, as fallback is optional
    }
  }
  
  /// Checks if an asset file exists
  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<List<String>> _loadLabels(String path) async {
    try {
      final labelsData = await rootBundle.loadString(path);
      return labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error loading labels from $path: $e');
      // Return a default label if we can't load the actual labels
      return ['Unknown'];
    }
  }
  
  /// Checks if an image is likely to be an orange based on color
  Future<bool> _isLikelyOrangeByColor(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) return false;
      
      // Sample pixels from the image to check for orange color
      int orangePixels = 0;
      int totalSamples = 0;
      
      // Track color distribution
      Map<String, int> colorCounts = {};
      
      // Sample grid of pixels with a reasonable step size
      final int sampleStep = max(2, min(8, image.width ~/ 50)); // Adaptive sampling based on image size
      
      for (int y = 0; y < image.height; y += sampleStep) {
        for (int x = 0; x < image.width; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          
          // Convert RGB to HSV for better color analysis
          final double r = pixel.r / 255.0;
          final double g = pixel.g / 255.0;
          final double b = pixel.b / 255.0;
          final hsv = _rgbToHsv(r, g, b);
          
          // Track color distribution
          final colorKey = "${(hsv[0] * 36).floor()}";
          colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;

          // Enhanced detection using HSV space - stricter orange hue range
          bool isOrangeHue = (hsv[0] >= 0.04 && hsv[0] <= 0.14); // 15-50 degrees - narrower orange range
          
          if (isOrangeHue && 
              hsv[1] > 0.4 && // Higher saturation requirement
              hsv[2] > 0.25 && // Not too dark
              pixel.r > pixel.g && pixel.g > pixel.b) { // RGB relationship
            orangePixels++;
          }
          // Also check using traditional RGB method as fallback - with stricter conditions
          else if ((pixel.r > 150 && // Higher red component requirement
               pixel.g > 50 && pixel.g < 180 && // Narrower green range
               pixel.b < 80 && // Lower blue threshold
               pixel.r > pixel.g * 1.3 && // Red must be significantly higher than green
               pixel.g > pixel.b * 1.4) || // Green must be significantly higher than blue
              // Additional check for brighter oranges
              (pixel.r > 200 && pixel.g > 100 && pixel.g < 160 && pixel.b < 70)) {
            orangePixels++;
          }
          totalSamples++;
        }
      }
      
      // Calculate the ratio of orange pixels
      final orangeRatio = orangePixels / totalSamples;
      debugPrint('Orange color detection: orangeRatio=$orangeRatio');
      
      // Analyze color distribution for better decision
      bool hasOrangePeak = false;
      int orangeHueCount = 0;
      int totalColors = 0;
      
      if (colorCounts.isNotEmpty) {
        // Check the proportion of orange hues in the image
        for (final entry in colorCounts.entries) {
          final hue = int.parse(entry.key) / 36;
          totalColors += entry.value;
          
          if (hue >= 0.04 && hue <= 0.14) { // Orange hue range
            orangeHueCount += entry.value;
          }
        }
        
        // Sort colors by frequency
        final sortedColors = colorCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // Check if any top colors are in orange range (must be in top 2 colors)
        for (int i = 0; i < min(2, sortedColors.length); i++) {
          final hue = int.parse(sortedColors[i].key) / 36;
          if (hue >= 0.04 && hue <= 0.14) {
            hasOrangePeak = true;
            break;
          }
        }
      }
      
      // Calculate the proportion of orange hues
      final orangeHueRatio = totalColors > 0 ? orangeHueCount / totalColors : 0.0;
      
      debugPrint("Enhanced orange detection: ratio=$orangeRatio, orangeHueRatio=$orangeHueRatio, hasOrangePeak=$hasOrangePeak");
      
      // Stricter decision logic with multiple conditions
      if (orangeRatio > 0.35) {
        return true; // Strong orange presence
      } else if (orangeRatio > 0.25 && hasOrangePeak && orangeHueRatio > 0.3) {
        return true; // Moderate orange that's a dominant color
      }
      
      return false;
    } catch (e) {
      debugPrint('Error in color detection: $e');
      return false;
    }
  }
  
  /// Enhanced mold detection using HSV color space and multi-factor analysis
  Future<MoldAnalysisResult> _analyzeQualityFactors(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return MoldAnalysisResult(
          hasMold: false, 
          hasDarkSpots: false,
          moldConfidence: 0.0,
          darkSpotsConfidence: 0.0,
          texturalAnomaly: false,
          colorConsistency: 1.0,
          surfaceIrregularities: 0.0
        );
      }
      
      // The counts and thresholds for different quality issues
      int moldPixels = 0;
      int darkSpotsPixels = 0;
      int surfaceAnomalyPixels = 0;
      List<Point> darkSpotPoints = [];
      List<double> pixelDifferences = []; // For texture analysis
      int totalPixels = 0;
      
      // Color consistency metrics
      List<double> hueSamples = [];
      double hueSum = 0;
      List<Point> moldPoints = [];
      
      // Sample grid of pixels with a higher density in problematic areas
      const int sampleStep = 4; // Higher detail sampling
      
      // Collect sample colors to establish baseline
      Map<String, int> colorBuckets = {};
      
      // For surface irregularity detection
      List<List<double>> brightnessMap = List.generate(
        image.height ~/ sampleStep + 1,
        (_) => List.filled(image.width ~/ sampleStep + 1, 0.0),
      );
      
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
          
          // Store brightness in the map for texture analysis
          brightnessMap[y ~/ sampleStep][x ~/ sampleStep] = value;
          
          // Add to hue samples for consistency calculation
          if (saturation > 0.2 && value > 0.2) { // Only consider colored pixels
            hueSamples.add(hue);
            hueSum += hue;
            
            // Collect color buckets for distribution analysis
            final bucketKey = '${(hue * 10).floor()}_${(saturation * 10).floor()}';
            colorBuckets[bucketKey] = (colorBuckets[bucketKey] ?? 0) + 1;
          }
          
          // BLUE-GREEN MOLD DETECTION (improved)
          // Mold on oranges typically appears as blue/green/white spots
          // - Blue-green mold: HSV with hue in blue-green range
          // - White mold: High value, low saturation
          if ((hue > 110/360 && hue < 200/360 && saturation > 0.15 && value > 0.3) || // Blue-green range
              (saturation < 0.2 && value > 0.8 && r > 200 && g > 200 && b > 200)) {   // White fuzzy mold
            moldPixels++;
            moldPoints.add(Point(x, y));
          }
          
          // DARK SPOTS DETECTION (improved)
          // Rot or bruising appears as dark areas
          // Very low value (darkness) that isn't just shadows (check neighbors)
          if (value < 0.15) {
            // Check if it's likely a shadow or actual dark spot by looking at neighbors
            bool likelyShadow = false;
            
            // Simplified shadow detection - look at neighboring pixels
            if (x > 0 && y > 0 && x < image.width - 1 && y < image.height - 1) {
              final neighborPixels = [
                image.getPixel(x - sampleStep, y),
                image.getPixel(x + sampleStep, y),
                image.getPixel(x, y - sampleStep),
                image.getPixel(x, y + sampleStep),
              ];
              
              // If at least two neighbors are significantly brighter, it might be a shadow
              int brighterNeighbors = 0;
              for (final np in neighborPixels) {
                final npBrightness = (np.r + np.g + np.b) / (3 * 255);
                if (npBrightness > value + 0.3) { // Significantly brighter
                  brighterNeighbors++;
                }
              }
              
              if (brighterNeighbors >= 2) {
                likelyShadow = true;
              }
            }
            
            if (!likelyShadow) {
              darkSpotsPixels++;
              darkSpotPoints.add(Point(x, y));
            }
          }
        }
      }
      
      // Process the brightness map to detect surface irregularities
      double surfaceIrregularityScore = 0.0;
      int irregularityCount = 0;
      
      // Calculate local variations in brightness to detect bumps, dents, scratches
      for (int y = 1; y < brightnessMap.length - 1; y++) {
        for (int x = 1; x < brightnessMap[y].length - 1; x++) {
          final centerValue = brightnessMap[y][x];
          
          // Sample neighbors in 8 directions
          final neighbors = [
            brightnessMap[y-1][x-1], brightnessMap[y-1][x], brightnessMap[y-1][x+1],
            brightnessMap[y][x-1],                           brightnessMap[y][x+1],
            brightnessMap[y+1][x-1], brightnessMap[y+1][x], brightnessMap[y+1][x+1],
          ];
          
          // Calculate average neighbor brightness
          final avgNeighbor = neighbors.reduce((a, b) => a + b) / neighbors.length;
          
          // Calculate the difference between center and average
          final diff = (centerValue - avgNeighbor).abs();
          
          // If there's a significant brightness change, it could be a surface irregularity
          if (diff > 0.15) {
            irregularityCount++;
            surfaceIrregularityScore += diff;
          }
        }
      }
      
      // Normalize the surface irregularity score between 0-1
      if (irregularityCount > 0) {
        // Average the differences and scale to 0-1 range
        surfaceIrregularityScore = min(1.0, (surfaceIrregularityScore / irregularityCount) * 3);
      }
      
      // Calculate mold cluster strength - mold tends to grow in clusters
      bool hasMoldCluster = _checkForMoldClusters(moldPoints, image.width, image.height, 8);
      
      // Calculate mold confidence based on pixel ratio and clusters
      double moldRatio = moldPixels / totalPixels;
      double moldConfidence = moldRatio * 10; // Scale up for better sensitivity
      if (hasMoldCluster) {
        moldConfidence += 0.3; // Boost confidence if clusters detected
      }
      
      // Cap at 1.0
      moldConfidence = moldConfidence > 1.0 ? 1.0 : moldConfidence;
      
      // Calculate dark spots confidence
      double darkSpotsRatio = darkSpotsPixels / totalPixels;
      double darkSpotsConfidence = darkSpotsRatio * 5; // Scale factor for sensitivity
      darkSpotsConfidence = darkSpotsConfidence > 1.0 ? 1.0 : darkSpotsConfidence;
      
      // Calculate color consistency score
      double colorConsistency = 1.0; // Default to perfect score
      
      if (hueSamples.length > 10) {
        // Calculate standard deviation of hue
        final avgHue = hueSum / hueSamples.length;
        double sumSquaredDiff = 0;
        
        for (final hue in hueSamples) {
          // Handle circular nature of hue
          double diff = (hue - avgHue).abs();
          if (diff > 0.5) diff = 1 - diff; // Hue wraps around at 1.0
          sumSquaredDiff += diff * diff;
        }
        
        double hueStdDev = sqrt(sumSquaredDiff / hueSamples.length);
        
        // Convert to a consistency score (0-1)
        // For oranges, we expect some variation but not too much
        colorConsistency = 1 - (hueStdDev * 6);
        colorConsistency = colorConsistency < 0 ? 0 : (colorConsistency > 1 ? 1 : colorConsistency);
      }
      
      // Check for color distribution anomalies (rare colors that might indicate issues)
      bool texturalAnomaly = false;
      if (colorBuckets.length > 5) {
        // Sort buckets by frequency
        final sortedBuckets = colorBuckets.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
          
        // Check if any unusual colors appear in more than trace amounts
        int totalSamples = sortedBuckets.fold(0, (sum, entry) => sum + entry.value);
        
        for (int i = 0; i < sortedBuckets.length; i++) {
          final bucketRatio = sortedBuckets[i].value / totalSamples;
          
          // Skip dominant colors
          if (i < 3) continue;
          
          // If a non-dominant color appears in more than 3% of samples, it might be an anomaly
          if (bucketRatio > 0.03) {
            final bucketKey = sortedBuckets[i].key.split('_');
            final bucketHue = int.parse(bucketKey[0]) / 10;
            
            // If this color is in blue/green/gray range (not orange/yellow), it's suspicious
            if ((bucketHue > 0.3 && bucketHue < 0.7) || bucketHue > 0.8) {
              texturalAnomaly = true;
              break;
            }
          }
        }
      }
      
      // Debug output
      debugPrint('ENHANCED QUALITY ANALYSIS:');
      debugPrint('Mold: $moldRatio ($moldConfidence), Clusters: $hasMoldCluster');
      debugPrint('Dark spots: $darkSpotsRatio ($darkSpotsConfidence)');
      debugPrint('Color consistency: $colorConsistency');
      debugPrint('Textural anomaly: $texturalAnomaly');
      debugPrint('Surface irregularities: $surfaceIrregularityScore');
      
      return MoldAnalysisResult(
        hasMold: moldConfidence > 0.15, 
        hasDarkSpots: darkSpotsConfidence > 0.2,
        moldConfidence: moldConfidence,
        darkSpotsConfidence: darkSpotsConfidence,
        texturalAnomaly: texturalAnomaly,
        colorConsistency: colorConsistency,
        surfaceIrregularities: surfaceIrregularityScore
      );
      
    } catch (e) {
      debugPrint('Error in quality analysis: $e');
      return MoldAnalysisResult(
        hasMold: false, 
        hasDarkSpots: false,
        moldConfidence: 0.0,
        darkSpotsConfidence: 0.0,
        texturalAnomaly: false,
        colorConsistency: 1.0,
        surfaceIrregularities: 0.0
      );
    }
  }
  
  /// Convert RGB to HSV color space for better color analysis
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
  
  /// Check for clusters of mold (mold tends to grow in concentrated areas)
  bool _checkForMoldClusters(List<Point> moldPoints, int imageWidth, int imageHeight, [int requiredClusterSize = 6]) {
    if (moldPoints.length < requiredClusterSize) return false;
    
    // Enhanced clustering check with weighted proximity
    // Create a grid to track point density
    int gridSize = 20; // Split the image into 20x20 grid
    List<List<int>> densityGrid = List.generate(
      gridSize, 
      (_) => List.filled(gridSize, 0)
    );
    
    // Map points to grid cells and count
    for (final point in moldPoints) {
      int gridX = (point.x / imageWidth * gridSize).floor();
      int gridY = (point.y / imageHeight * gridSize).floor();
      
      // Bound check
      gridX = gridX.clamp(0, gridSize - 1);
      gridY = gridY.clamp(0, gridSize - 1);
      
      // Increment cell and neighbors for smoother clustering
      densityGrid[gridY][gridX]++;
      
      // Add to neighboring cells with smaller weight
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue; // Skip center
          
          final nx = gridX + dx;
          final ny = gridY + dy;
          
          if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
            densityGrid[ny][nx] += 1; // Use integer value for density grid
          }
        }
      }
    }
    
    // Check for high-density cells
    for (final row in densityGrid) {
      for (final cell in row) {
        if (cell >= requiredClusterSize) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Classifies an image using primary and fallback models as needed
  Future<ClassificationResult> classifyImage(File imageFile) async {
    try {
      // Validate the image quality first
      final isValid = await ImageQualityChecker.isValidImage(imageFile);
      if (!isValid) {
        return ClassificationResult.error('Invalid image - does not meet quality requirements');
      }
      
      // Check if the image is likely an orange based on color
      final isLikelyOrange = await _isLikelyOrangeByColor(imageFile);
      debugPrint('Color detection suggests this is likely an orange: $isLikelyOrange');
      
      // Enhanced quality analysis to detect multiple issues
      final qualityAnalysis = await _analyzeQualityFactors(imageFile);
      debugPrint('Quality analysis complete: ${qualityAnalysis.toString()}');
      
      // Load models first so we can use them for classification
      if (_interpreter == null || _labels == null || (_labels?.isEmpty ?? true)) {
        try {
          await loadModels();
        } catch (e) {
          debugPrint('Error loading models: $e');
          // Continue with color-based detection if models fail to load
        }
      }
      
      // Run primary model classification if available
      Map<String, double> primaryResults = {};
      String primaryLabel = '';
      double primaryConfidence = 0.0;
      
      if (_interpreter != null && _labels != null && _labels!.isNotEmpty) {
        primaryResults = await _runPrimaryClassification(imageFile);
        
        // Get the highest confidence label and value
        final sortedPrimary = primaryResults.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        primaryLabel = sortedPrimary.isNotEmpty ? sortedPrimary.first.key : 'Unknown';
        primaryConfidence = sortedPrimary.isNotEmpty ? sortedPrimary.first.value : 0.0;
        
        debugPrint('Primary classification: $primaryLabel with confidence $primaryConfidence');
      }
      
      // DECISION LOGIC - Improved for multi-class classification
      
      // Calculate overall quality score (0-1) based on all factors
      double qualityScore = 1.0; // Start with perfect score
      
      // Reduce score based on detected issues
      if (qualityAnalysis.hasMold) {
        qualityScore -= qualityAnalysis.moldConfidence * 0.8; // Heavily penalize mold
      }
      
      if (qualityAnalysis.hasDarkSpots) {
        qualityScore -= qualityAnalysis.darkSpotsConfidence * 0.6; // Penalize dark spots
      }
      
      if (qualityAnalysis.texturalAnomaly) {
        qualityScore -= 0.3; // Penalize textural anomalies
      }
      
      // Incorporate surface irregularity penalties
      if (qualityAnalysis.surfaceIrregularities > 0.1) {
        // Apply a penalty proportional to the severity of irregularities
        qualityScore -= qualityAnalysis.surfaceIrregularities * 0.5;
      }
      
      // Consider color consistency
      qualityScore *= qualityAnalysis.colorConsistency;
      
      // Ensure score is in 0-1 range
      qualityScore = qualityScore < 0 ? 0 : (qualityScore > 1 ? 1 : qualityScore);
      
      debugPrint('Final quality score: $qualityScore');
      
      // ADVANCED CLASSIFICATION LOGIC
      
      // Case 1: Not an orange at all
      if (!isLikelyOrange) {
        if (_fallbackInterpreter != null && _fallbackLabels != null && 
            (_fallbackLabels?.isNotEmpty ?? false)) {
          final fallbackResults = await _runFallbackClassification(imageFile);
          
          // Get the highest confidence fallback label and value
          final sortedFallback = fallbackResults.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
            
          final fallbackLabel = sortedFallback.isNotEmpty ? sortedFallback.first.key : 'Unknown';
          final fallbackConfidence = sortedFallback.isNotEmpty ? sortedFallback.first.value : 0.0;
          
          return ClassificationResult.lowConfidence(
            primaryLabel,
            primaryConfidence,
            fallbackLabel,
            fallbackConfidence
          );
        }
        
        return ClassificationResult(
          primaryLabel: 'Not an Orange',
          primaryConfidence: 0.8,
        );
      }
      
      // Case 2: Specific quality issues with multi-class detection
      
      // Mold detection
      if (qualityAnalysis.hasMold && qualityAnalysis.moldConfidence > 0.3) {
        return ClassificationResult(
          primaryLabel: 'Moldy',
          primaryConfidence: qualityAnalysis.moldConfidence * 0.9 + 0.1,
          details: 'Mold detected on the orange surface',
        );
      }
      
      // Rot/dark spots severe detection
      if (qualityAnalysis.hasDarkSpots && qualityAnalysis.darkSpotsConfidence > 0.4) {
        return ClassificationResult(
          primaryLabel: 'Rotten',
          primaryConfidence: qualityAnalysis.darkSpotsConfidence * 0.8 + 0.15,
          details: 'Extensive dark spots or rot detected',
        );
      }
      
      // Surface damage detection
      if (qualityAnalysis.surfaceIrregularities > 0.4) {
        return ClassificationResult(
          primaryLabel: 'Surface Damaged',
          primaryConfidence: qualityAnalysis.surfaceIrregularities * 0.8 + 0.15,
          details: 'Significant surface damage detected',
        );
      }
      
      // Unripe detection based on color consistency and hue analysis
      // (Would need more comprehensive color analysis for accurate unripe detection)
      if (qualityAnalysis.colorConsistency < 0.5 && !qualityAnalysis.hasMold && !qualityAnalysis.hasDarkSpots) {
        // Additional logic would be needed here for better unripe detection
        return ClassificationResult(
          primaryLabel: 'Unripe',
          primaryConfidence: 0.75,
          details: 'Color pattern suggests an unripe orange',
        );
      }
      
      // Case 3: Fair quality - some issues detected but not severe
      if (qualityScore < 0.7) {
        return ClassificationResult(
          primaryLabel: 'Fair Quality',
          primaryConfidence: 0.8,
          details: 'Minor imperfections detected',
        );
      }
      
      // Case 4: Good quality orange
      return ClassificationResult(
        primaryLabel: 'Good Quality',
        primaryConfidence: qualityScore,
        details: 'No significant issues detected',
      );
      
    } catch (e) {
      debugPrint('Error classifying image: $e');
      return ClassificationResult.error('Classification error: $e');
    }
  }
  
  /// Runs the primary orange classifier model
  Future<Map<String, double>> _runPrimaryClassification(File imageFile) async {
    try {
      final image = await _preprocessImage(imageFile);
      
      // Determine output shape and prepare output tensor accordingly
      if (outputShape == null || outputShape!.isEmpty) {
        // Fallback if we couldn't get output shape
        debugPrint('Using default output shape based on labels length');
        outputShape = [1, _labels?.length ?? 2];
      }
      
      // Create output tensor with proper dimensions
      final output = List.generate(
        outputShape![0], 
        (_) => List<double>.filled(outputShape![1], 0)
      );
      
      // Run inference
      _interpreter!.run(image, output);
      
      // Process results - map to labels
      Map<String, double> results = {};
      
      // If the output is a single value (binary classification)
      if (outputShape![1] == 1) {
        // Binary classification - first output is probability of positive class
        double prediction = output[0][0];
        results[_labels != null && _labels!.isNotEmpty ? _labels![0] : 'Good Quality'] = prediction;
        results[_labels != null && _labels!.length > 1 ? _labels![1] : 'Bad Quality'] = 1.0 - prediction;
      } else {
        // Multi-class classification
        for (int i = 0; i < (_labels?.length ?? 0); i++) {
          if (i < outputShape![1]) {
            String label = _labels?[i] ?? 'Class_$i';
            double value = output[0][i];
            results[label] = value;
          }
        }
      }
      
      debugPrint('Classification results: $results');
      return results;
    } catch (e) {
      debugPrint('Error in primary classification: $e');
      return {'Error': 0.0};
    }
  }
  
  /// Runs the fallback classification model for non-orange objects
  Future<Map<String, double>> _runFallbackClassification(File imageFile) async {
    try {
      final image = await _preprocessImage(imageFile);
      
      // Get fallback model shape if available
      List<int> fallbackOutputShape;
      try {
        fallbackOutputShape = _fallbackInterpreter!.getOutputTensor(0).shape;
      } catch (_) {
        // Default fallback shape if we can't get it
        fallbackOutputShape = [1, _fallbackLabels?.length ?? 1];
      }
      
      // Create output tensor with proper dimensions
      final output = List.generate(
        fallbackOutputShape[0], 
        (_) => List<double>.filled(fallbackOutputShape[1], 0)
      );
      
      // Run inference with fallback model
      _fallbackInterpreter!.run(image, output);
      
      // Process results - map to labels
      Map<String, double> results = {};
      
      // Handle different output formats
      if (fallbackOutputShape[1] == 1) {
        // Binary classification
        double prediction = output[0][0];
        results[_fallbackLabels != null && _fallbackLabels!.isNotEmpty ? _fallbackLabels![0] : 'Positive'] = prediction;
        results[_fallbackLabels != null && _fallbackLabels!.length > 1 ? _fallbackLabels![1] : 'Negative'] = 1.0 - prediction;
      } else {
        // Multi-class classification
        for (int i = 0; i < (_fallbackLabels?.length ?? 0); i++) {
          if (i < fallbackOutputShape[1]) {
            String label = _fallbackLabels?[i] ?? 'Class_$i';
            double value = output[0][i];
            results[label] = value;
          }
        }
      }
      
      debugPrint('Fallback classification results: $results');
      return results;
    } catch (e) {
      debugPrint('Error in fallback classification: $e');
      return {'Error': 0.0};
    }
  }
  
  /// Preprocesses an image for model input
  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    try {
      // Read and decode the image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize the image to match model input size
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );
      
      // Check input shape to determine format
      // Some models expect [1, height, width, 3] while others expect [height, width, 3]
      bool includeBatchDim = inputShape != null && inputShape!.length == 4;
      
      if (includeBatchDim) {
        // Format with batch dimension: [1, height, width, 3]
        final result = List<List<List<List<double>>>>.generate(
          1,
          (_) => List<List<List<double>>>.generate(
            inputSize,
            (_) => List<List<double>>.generate(
              inputSize,
              (_) => List<double>.filled(3, 0),
            ),
          ),
        );
        
        // Normalize pixel values to [0, 1]
        for (int y = 0; y < inputSize; y++) {
          for (int x = 0; x < inputSize; x++) {
            final pixel = resizedImage.getPixel(x, y);
            result[0][y][x][0] = pixel.r / 255.0;
            result[0][y][x][1] = pixel.g / 255.0;
            result[0][y][x][2] = pixel.b / 255.0;
          }
        }
        
        return result;
      } else {
        // Format without batch dimension: [height, width, 3]
        final result = List<List<List<double>>>.generate(
          inputSize,
          (_) => List<List<double>>.generate(
            inputSize,
            (_) => List<double>.filled(3, 0),
          ),
        );
        
        // Normalize pixel values to [0, 1]
        for (int y = 0; y < inputSize; y++) {
          for (int x = 0; x < inputSize; x++) {
            final pixel = resizedImage.getPixel(x, y);
            result[y][x][0] = pixel.r / 255.0;
            result[y][x][1] = pixel.g / 255.0;
            result[y][x][2] = pixel.b / 255.0;
          }
        }
        
        return [result];
      }
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      rethrow;
    }
  }
  
  /// Disposes resources used by the models
  void dispose() {
    _interpreter?.close();
    _fallbackInterpreter?.close();
  }
} 

/// Result of analyzing mold and other quality factors
class MoldAnalysisResult {
  final bool hasMold;
  final bool hasDarkSpots;
  final double moldConfidence;
  final double darkSpotsConfidence;
  final bool texturalAnomaly;
  final double surfaceIrregularities;
  final double colorConsistency;
  
  MoldAnalysisResult({
    required this.hasMold,
    required this.hasDarkSpots,
    required this.moldConfidence,
    required this.darkSpotsConfidence,
    required this.texturalAnomaly,
    required this.colorConsistency,
    required this.surfaceIrregularities,
  });
  
  @override
  String toString() {
    return 'MoldAnalysisResult(hasMold: $hasMold, hasDarkSpots: $hasDarkSpots, ' 'moldConfidence: $moldConfidence, darkSpotsConfidence: $darkSpotsConfidence, ' +
           'texturalAnomaly: $texturalAnomaly, colorConsistency: $colorConsistency, ' +
           'surfaceIrregularities: $surfaceIrregularities)';
  }
} 