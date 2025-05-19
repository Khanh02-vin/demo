import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import 'gradient_card.dart';
import 'package:intl/intl.dart';

class AnalysisResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isExpanded;
  final Function()? onTap;
  final bool animate;
  final String? imagePath;
  final String? timestamp;

  const AnalysisResultCard({
    super.key,
    required this.result,
    this.isExpanded = false,
    this.onTap,
    this.animate = false,
    this.imagePath,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGoodQuality = result['overallQuality'] == 'Good' || 
                              result['confidence'] > 0.7;
    
    final Color statusColor = isGoodQuality 
        ? AppTheme.success 
        : (result['hasMold'] == true ? AppTheme.error : AppTheme.warning);
    
    final String statusText = isGoodQuality 
        ? 'Good Quality' 
        : (result['hasMold'] == true ? 'Bad Quality - Mold Detected' : 'Poor Quality');
    
    final Icon statusIcon = Icon(
      isGoodQuality 
          ? Icons.check_circle
          : (result['hasMold'] == true ? Icons.dangerous : Icons.warning),
      color: statusColor,
      size: 24,
    );

    return GradientCard(
      animate: animate,
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    statusIcon,
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        statusText,
                        style: AppTheme.headingSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (timestamp != null)
                Text(
                  _formatDate(timestamp!),
                  style: AppTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          
          // Row with image preview and confidence bars
          if (isExpanded && imagePath != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview
                                 ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: imagePath != null 
                      ? Image.file(
                          File(imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.cardLight,
                              child: const Icon(
                                Icons.broken_image,
                                color: AppTheme.textMedium,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.cardLight,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppTheme.textMedium,
                            size: 40,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                
                // Confidence meters
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConfidenceMeter(
                        'Confidence', 
                        result['confidence'] ?? 0.0,
                        isGoodQuality ? AppTheme.success : AppTheme.warning,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      if (result.containsKey('moldConfidence'))
                        _buildConfidenceMeter(
                          'Mold Detection', 
                          result['moldConfidence'] ?? 0.0,
                          result['hasMold'] == true ? AppTheme.error : AppTheme.success,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
          
          // Detailed metrics for expanded view
          if (isExpanded) ...[
            Text(
              'Quality Metrics',
              style: AppTheme.labelLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildDetailGrid(result),
          ] 
          // Summary for collapsed view
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricChip(
                  'Confidence',
                  '${((result['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.analytics_outlined,
                ),
                if (result.containsKey('colorConsistency'))
                  _buildMetricChip(
                    'Color',
                    '${((result['colorConsistency'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                    icon: Icons.palette_outlined,
                  ),
                if (result.containsKey('hasMold'))
                  _buildMetricChip(
                    'Mold',
                    result['hasMold'] == true ? 'Detected' : 'None',
                    icon: Icons.bug_report_outlined,
                    isNegative: result['hasMold'] == true,
                  ),
              ],
            ),
          ],
          
          // Tap to expand hint
          if (!isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingMd),
              child: Center(
                child: Text(
                  'Tap for details',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildConfidenceMeter(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Stack(
          children: [
            // Background
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 10,
              width: double.infinity * value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          '${(value * 100).toStringAsFixed(0)}%',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildMetricChip(String label, String value, {
    IconData? icon,
    bool isNegative = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingSm, 
        horizontal: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isNegative ? AppTheme.error.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isNegative ? AppTheme.error : AppTheme.textMedium,
            ),
            const SizedBox(width: 4),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textMedium,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  color: isNegative ? AppTheme.error : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailGrid(Map<String, dynamic> data) {
    final metrics = <Widget>[];
    
    // Add metrics from the result data that we want to display
    if (data.containsKey('colorConsistency')) {
      metrics.add(_buildDetailItem(
        'Color Consistency', 
        '${((data['colorConsistency'] ?? 0.0) * 100).toStringAsFixed(0)}%',
        Icons.palette_outlined,
      ));
    }
    
    if (data.containsKey('surfaceIrregularities')) {
      metrics.add(_buildDetailItem(
        'Surface Quality', 
        '${((1 - (data['surfaceIrregularities'] ?? 0.0)) * 100).toStringAsFixed(0)}%',
        Icons.texture,
      ));
    }
    
    if (data.containsKey('hasDarkSpots')) {
      metrics.add(_buildDetailItem(
        'Dark Spots', 
        data['hasDarkSpots'] == true ? 'Detected' : 'None',
        Icons.blur_circular,
        isNegative: data['hasDarkSpots'] == true,
      ));
    }
    
    if (data.containsKey('hasMold')) {
      metrics.add(_buildDetailItem(
        'Mold', 
        data['hasMold'] == true ? 'Detected' : 'None',
        Icons.bug_report_outlined,
        isNegative: data['hasMold'] == true,
      ));
    }
    
    if (data.containsKey('texturalAnomaly')) {
      metrics.add(_buildDetailItem(
        'Texture Anomalies', 
        data['texturalAnomaly'] == true ? 'Detected' : 'None',
        Icons.grain,
        isNegative: data['texturalAnomaly'] == true,
      ));
    }
    
    // Fill extra space with empty containers to maintain grid layout
    while (metrics.length % 2 != 0) {
      metrics.add(const SizedBox.shrink());
    }
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 3,
      crossAxisSpacing: AppTheme.spacingMd,
      mainAxisSpacing: AppTheme.spacingMd,
      physics: const NeverScrollableScrollPhysics(),
      children: metrics,
    );
  }
  
  Widget _buildDetailItem(String label, String value, IconData icon, {bool isNegative = false}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isNegative ? AppTheme.error.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isNegative ? AppTheme.error : AppTheme.textMedium,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: AppTheme.bodySmall.copyWith(
                    color: isNegative ? AppTheme.error : AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }
} 