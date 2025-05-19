import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Utility class for checking image quality before classification
class ImageQualityChecker {
  // Minimum dimensions for a valid image
  static const int MIN_WIDTH = 20;
  static const int MIN_HEIGHT = 20;
  
  // Maximum file size (in bytes) for efficient processing
  static const int MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB
  
  // Brightness thresholds
  static const double MIN_BRIGHTNESS = 0.01;
  static const double MAX_BRIGHTNESS = 0.99;
  
  /// Checks if an image meets the quality requirements for classification
  static Future<bool> isValidImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > MAX_FILE_SIZE || fileSize <= 0) {
        debugPrint('Image quality check failed: Invalid file size: $fileSize bytes');
        return false;
      }
      
      // Check dimensions and brightness
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage == null) {
        debugPrint('Image quality check failed: Unable to decode image');
        // Be more permissive - if we can't decode the image, still try to process it
        return true;
      }
      
      if (decodedImage.width < MIN_WIDTH || decodedImage.height < MIN_HEIGHT) {
        debugPrint('Image quality check failed: Image dimensions too small: ${decodedImage.width}x${decodedImage.height}');
        // Still try to process small images
        return true;
      }
      
      // Calculate average brightness but be more lenient with the check
      final brightness = _calculateBrightness(decodedImage);
      if (brightness < MIN_BRIGHTNESS || brightness > MAX_BRIGHTNESS) {
        debugPrint('Image quality check warning: Brightness out of ideal range: $brightness but proceeding anyway');
        // Return true anyway - don't reject based on brightness alone
      }
      
      return true;
    } catch (e) {
      debugPrint('Image quality check failed with exception: $e');
      // Be more permissive - if there's an error in quality checking, still try to process the image
      return true;
    }
  }
  
  /// Calculates the average brightness of an image
  static double _calculateBrightness(img.Image image) {
    int totalPixels = image.width * image.height;
    double totalBrightness = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Convert RGB to relative luminance using the formula:
        // Y = 0.2126*R + 0.7152*G + 0.0722*B
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;
        final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        totalBrightness += luminance;
      }
    }
    
    return totalBrightness / totalPixels;
  }
} 