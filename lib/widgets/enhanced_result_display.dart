import 'package:flutter/material.dart';
import '../models/classification_result.dart';

class EnhancedResultDisplay extends StatelessWidget {
  final ClassificationResult result;
  
  const EnhancedResultDisplay({super.key, required this.result});
  
  @override
  Widget build(BuildContext context) {
    if (!result.isValid) {
      return _buildErrorDisplay(context);
    }
    
    // First check if explicitly classified as not an orange
    if (result.primaryLabel.toLowerCase().contains('not an orange') || 
        result.primaryLabel.toLowerCase() == 'not orange') {
      return _buildNonOrangeResultDisplay(context);
    }
    
    // Modified logic: Always assume it's an orange unless specifically 
    // proven to be something else with high confidence
    
    // If primary result contains orange/quality keywords OR has reasonable confidence,
    // show it as an orange result
    if (_isOrangeRelatedLabel(result.primaryLabel) || result.primaryConfidence > 0.3) {
      return _buildOrangeResultDisplay(context);
    }
    
    // If fallback model detected a fruit/citrus/orange, show as orange
    if (result.usedFallback && 
        result.fallbackLabel != null && 
        (result.fallbackLabel!.toLowerCase().contains('fruit') ||
         result.fallbackLabel!.toLowerCase().contains('citrus') ||
         result.fallbackLabel!.toLowerCase().contains('orange'))) {
      return _buildOrangeResultDisplay(context);
    }
    
    // If we have an error or extremely low confidence and no other evidence,
    // only then show as non-orange
    if (result.primaryConfidence < 0.1 && 
        !(result.usedFallback && result.fallbackConfidence != null && result.fallbackConfidence! > 0.3)) {
      return _buildNonOrangeResultDisplay(context);
    }
    
    // Default case: If in doubt, show it as an orange
    return _buildOrangeResultDisplay(context);
  }
  
  bool _isOrangeRelatedLabel(String label) {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('quality') || 
           lowerLabel.contains('orange') || 
           lowerLabel.contains('moldy') ||
           lowerLabel.contains('surface') ||
           lowerLabel.contains('rotten') ||
           lowerLabel.contains('unripe');
  }
  
  Widget _buildErrorDisplay(BuildContext context) {
    // Combine error message with details if available
    final errorText = result.errorMessage ?? 'Unknown error occurred';
    final additionalDetails = result.details != null ? '\n\n${result.details}' : '';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            errorText + additionalDetails,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Try scanning a different image or try again with better lighting',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrangeResultDisplay(BuildContext context) {
    // Get display configuration based on category
    final config = _getDisplayConfig();
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orange Quality',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(
            label: result.primaryLabel,
            confidence: result.primaryConfidence,
            isHighlighted: true,
            customColor: config.barColor,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: config.borderColor,
              ),
            ),
            child: Text(
              result.details ?? config.defaultDescription,
              style: TextStyle(
                fontSize: 14,
                color: config.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  DisplayConfig _getDisplayConfig() {
    final label = result.primaryLabel.toLowerCase();
    
    if (label.contains('good quality')) {
      return DisplayConfig(
        barColor: Colors.green,
        backgroundColor: Colors.green.shade50,
        borderColor: Colors.green.shade200,
        textColor: Colors.green.shade800,
        defaultDescription: 'This orange appears to be of excellent quality with no defects.',
      );
    } else if (label.contains('fair quality')) {
      return DisplayConfig(
        barColor: Colors.yellow.shade700,
        backgroundColor: Colors.yellow.shade50,
        borderColor: Colors.yellow.shade200,
        textColor: Colors.yellow.shade800,
        defaultDescription: 'This orange has minor imperfections but is still of acceptable quality.',
      );
    } else if (label.contains('surface damaged')) {
      return DisplayConfig(
        barColor: Colors.orange,
        backgroundColor: Colors.orange.shade50,
        borderColor: Colors.orange.shade200,
        textColor: Colors.orange.shade800,
        defaultDescription: 'This orange has significant surface damage or bruising.',
      );
    } else if (label.contains('moldy')) {
      return DisplayConfig(
        barColor: Colors.red.shade800,
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade200,
        textColor: Colors.red.shade800,
        defaultDescription: 'This orange appears to have mold growing on the surface.',
      );
    } else if (label.contains('rotten')) {
      return DisplayConfig(
        barColor: Colors.deepPurple,
        backgroundColor: Colors.deepPurple.shade50,
        borderColor: Colors.deepPurple.shade200,
        textColor: Colors.deepPurple.shade800,
        defaultDescription: 'This orange shows signs of rot or severe dark spots.',
      );
    } else if (label.contains('unripe')) {
      return DisplayConfig(
        barColor: Colors.lightGreen,
        backgroundColor: Colors.lightGreen.shade50,
        borderColor: Colors.lightGreen.shade200,
        textColor: Colors.lightGreen.shade800,
        defaultDescription: 'This orange appears to be unripe based on its color pattern.',
      );
    } else {
      // Default colors for other cases
      return DisplayConfig(
        barColor: Colors.red,
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade200,
        textColor: Colors.red.shade800,
        defaultDescription: 'This item has quality issues.',
      );
    }
  }
  
  Widget _buildNonOrangeResultDisplay(BuildContext context) {
    // Modified to provide a more accurate message for non-orange items
    final detailsText = result.details ?? 'This does not appear to be an orange.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not an Orange',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detailsText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          if (result.usedFallback && result.fallbackLabel != null)
            _buildResultRow(
              label: result.fallbackLabel!,
              confidence: result.fallbackConfidence ?? 0.0,
              isHighlighted: true,
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Primary Classification (Low Confidence):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            label: result.primaryLabel,
            confidence: result.primaryConfidence,
            isHighlighted: false,
          ),
          const SizedBox(height: 16),
          Text(
            'Try with an orange or similar fruit.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultRow({
    required String label, 
    required double confidence,
    required bool isHighlighted,
    Color? customColor,
  }) {
    final percentage = (confidence * 100).toStringAsFixed(1);
    
    // Determine color based on label and confidence
    final Color color;
    if (customColor != null) {
      color = customColor;
    } else if (isHighlighted) {
      // Map colors based on label
      if (label.toLowerCase().contains('good')) {
        color = Colors.green;
      } else if (label.toLowerCase().contains('fair')) {
        color = Colors.yellow.shade700;
      } else if (label.toLowerCase().contains('surface')) {
        color = Colors.orange;
      } else if (label.toLowerCase().contains('moldy')) {
        color = Colors.red.shade800;
      } else if (label.toLowerCase().contains('rotten')) {
        color = Colors.deepPurple;
      } else if (label.toLowerCase().contains('unripe')) {
        color = Colors.lightGreen;
      } else if (confidence > 0.7) {
        color = Colors.blue;
      } else {
        color = Colors.orange;
      }
    } else {
      color = Colors.grey.shade500;
    }
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isHighlighted ? Colors.black87 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isHighlighted ? color : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
} 

// Helper class for display configuration
class DisplayConfig {
  final Color barColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String defaultDescription;
  
  DisplayConfig({
    required this.barColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.defaultDescription,
  });
} 