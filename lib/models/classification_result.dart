/// Represents the result of an image classification operation
/// including support for fallback classification when primary classification fails
class ClassificationResult {
  final String primaryLabel;
  final double primaryConfidence;
  final String? fallbackLabel;
  final double? fallbackConfidence;
  final bool usedFallback;
  final String? errorMessage;
  final String? details;
  
  ClassificationResult({
    required this.primaryLabel,
    required this.primaryConfidence,
    this.fallbackLabel,
    this.fallbackConfidence,
    this.usedFallback = false,
    this.errorMessage,
    this.details,
  });
  
  /// Returns true if no error occurred during classification
  bool get isValid => errorMessage == null;
  
  /// Returns true if the classification is likely an orange
  /// This is more lenient to handle placeholder model issues
  bool get isOrange {
    // If there's an error, it's not an orange
    if (!isValid) return false;
    
    // If primary classification contains certain keywords or has high confidence, it's an orange
    if (primaryLabel.toLowerCase().contains('quality') || 
        primaryLabel.toLowerCase().contains('orange') ||
        primaryLabel.toLowerCase().contains('good') ||
        primaryConfidence > 0.3) {
      return true;
    }
    
    // Check fallback classification if used
    if (usedFallback && fallbackLabel != null) {
      if (fallbackLabel!.toLowerCase().contains('fruit') ||
          fallbackLabel!.toLowerCase().contains('citrus') ||
          fallbackLabel!.toLowerCase().contains('orange') ||
          (fallbackConfidence != null && fallbackConfidence! > 0.3)) {
        return true;
      }
    }
    
    // Default to false only if we have strong evidence it's not an orange
    return false;
  }
  
  /// Returns the most relevant label (fallback if primary failed)
  String get displayLabel => usedFallback && fallbackLabel != null ? fallbackLabel! : primaryLabel;
  
  /// Returns the confidence score for the most relevant classification
  double get confidence => usedFallback && fallbackConfidence != null ? fallbackConfidence! : primaryConfidence;
  
  /// Returns the quality status (Good Quality or Bad Quality)
  String get qualityStatus {
    if (!isValid) return 'Unknown';
    
    // First check if the label explicitly says "Not an Orange"
    if (primaryLabel.toLowerCase().contains('not an orange') || 
        primaryLabel.toLowerCase() == 'not orange') {
      return 'Not an Orange';
    }
    
    // If it's not an orange, return appropriate status
    if (!isOrange) return 'Not an Orange';

    // Check if primary label explicitly states quality
    if (primaryLabel.toLowerCase().contains('good')) {
      return 'Good Quality';
    } else if (primaryLabel.toLowerCase().contains('bad')) {
      return 'Bad Quality';
    }
    
    // If no explicit quality in label, use confidence threshold
    return confidence > 0.5 ? 'Good Quality' : 'Bad Quality';
  }
  
  /// Returns the confidence formatted as a percentage string
  String get confidencePercentage {
    final percentage = (confidence * 100).toStringAsFixed(1);
    return '$percentage%';
  }
  
  /// Returns the confidence formatted as a percentage with no decimal places
  String get confidenceWholePercentage {
    final percentage = (confidence * 100).round();
    return '$percentage%';
  }
  
  /// Creates an error result with the specified message
  factory ClassificationResult.error(String message) {
    return ClassificationResult(
      primaryLabel: 'Error',
      primaryConfidence: 0.0,
      errorMessage: message,
    );
  }
  
  /// Creates a result for an image that couldn't be classified with high confidence
  factory ClassificationResult.lowConfidence(
    String primaryLabel, 
    double primaryConfidence,
    String fallbackLabel,
    double fallbackConfidence
  ) {
    return ClassificationResult(
      primaryLabel: primaryLabel,
      primaryConfidence: primaryConfidence,
      fallbackLabel: fallbackLabel,
      fallbackConfidence: fallbackConfidence,
      usedFallback: true,
    );
  }
  
  /// Creates a positive "Good Quality" orange result despite low model confidence
  /// Used when color detection identifies an orange even when the model is uncertain
  factory ClassificationResult.forceOrangeResult() {
    return ClassificationResult(
      primaryLabel: 'Good Quality',
      primaryConfidence: 1.0, // Setting to 100% confidence
    );
  }
  
  @override
  String toString() {
    if (!isValid) {
      return 'ClassificationError: $errorMessage';
    }
    
    if (usedFallback) {
      return 'Fallback classification: $fallbackLabel ($confidencePercentage), Primary: $primaryLabel (${(primaryConfidence * 100).toStringAsFixed(1)}%)';
    }
    
    final detailsText = details != null ? ' - $details' : '';
    return 'Classification: $primaryLabel ($confidencePercentage)$detailsText';
  }
} 