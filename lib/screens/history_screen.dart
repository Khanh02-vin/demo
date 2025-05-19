import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orange_quality_checker/providers/app_provider.dart';
import 'package:orange_quality_checker/widgets/empty_state.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/history_item.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(refreshableHistoryProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Analysis History'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: () => _showClearConfirmation(context, ref),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (historyItems) {
          if (historyItems.isEmpty) {
            return _buildEmptyHistory();
          }
          return _buildHistoryList(context, historyItems, ref);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading history: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          const Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your analyzed oranges will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryList(BuildContext context, List<HistoryItem> items, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => _deleteItem(context, item.id, ref),
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            child: _buildHistoryCard(context, item, dateFormat),
          ),
        );
      },
    );
  }
  
  Widget _buildHistoryCard(BuildContext context, HistoryItem item, DateFormat dateFormat) {
    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showHistoryDetails(context, item),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: item.resultColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    _getIconForResult(item.result),
                    color: item.resultColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.result,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.resultColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(item.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: _buildImage(item.imagePath),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Quality: ',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${(item.qualityScore * 100).toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getQualityColor(item.qualityScore),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Type: ',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              item.isOrange ? 'Orange' : 'Not an Orange',
                              style: TextStyle(
                                color: item.isOrange ? Colors.orange : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildQualityBar(item.qualityScore, _getQualityColor(item.qualityScore)),
                      ],
                    ),
                  ),
                  
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImage(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return Container(
          color: Colors.grey.shade800,
          child: const Icon(
            Icons.broken_image,
            color: Colors.white30,
          ),
        );
      }
      return Image.file(
        file,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Container(
        color: Colors.grey.shade800,
        child: const Icon(
          Icons.error_outline,
          color: Colors.white30,
        ),
      );
    }
  }
  
  Widget _buildQualityBar(double value, Color color) {
    return Stack(
      children: [
        // Background
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        // Progress
        Container(
          height: 6,
          width: 120 * value,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
  
  IconData _getIconForResult(String result) {
    switch (result) {
      case 'Good Quality':
        return Icons.check_circle;
      case 'Fair Quality':
        return Icons.sentiment_neutral;
      case 'Surface Damaged':
        return Icons.offline_bolt_outlined;
      case 'Rotten':
        return Icons.sentiment_very_dissatisfied;
      case 'Moldy':
        return Icons.warning_amber_rounded;
      case 'Not an Orange':
        return Icons.help_outline;
      default:
        return Icons.info_outline;
    }
  }
  
  Color _getQualityColor(double value) {
    if (value >= 0.8) return Colors.green.shade400;
    if (value >= 0.6) return Colors.lime.shade400;
    if (value >= 0.4) return Colors.amber.shade400;
    if (value >= 0.2) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
  
  void _showHistoryDetails(BuildContext context, HistoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 220,
                  child: _buildImage(item.imagePath),
                ),
              ),
              const SizedBox(height: 16),
              
              // Date and time
              Center(
                child: Text(
                  dateFormat.format(item.timestamp),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Main result
              Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        _getIconForResult(item.result),
                        size: 48,
                        color: item.resultColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.result,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: item.resultColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.isOrange 
                            ? 'This appears to be an orange'
                            : 'This does not appear to be an orange',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailQualityBar(
                        item.qualityScore,
                        _getQualityColor(item.qualityScore),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Detailed metrics
              const Text(
                'Detailed Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              if (item.detailedMetrics.containsKey('colorConsistency'))
                _buildDetailCard(
                  'Color Consistency',
                  item.detailedMetrics['colorConsistency'],
                  Icons.color_lens_outlined,
                  Colors.blue,
                  'Higher is better',
                ),
                
              if (item.detailedMetrics.containsKey('surfaceIrregularities'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildDetailCard(
                    'Surface Quality',
                    1.0 - (item.detailedMetrics['surfaceIrregularities'] as double),
                    Icons.layers_outlined,
                    Colors.teal,
                    'Higher is better',
                  ),
                ),
                
              if (item.detailedMetrics.containsKey('moldConfidence'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildRiskCard(
                    'Mold Risk',
                    item.detailedMetrics['moldConfidence'],
                    Icons.bug_report_outlined,
                    Colors.purple,
                    'Lower is better',
                  ),
                ),
                
              if (item.detailedMetrics.containsKey('darkSpotsConfidence'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildRiskCard(
                    'Rot Risk',
                    item.detailedMetrics['darkSpotsConfidence'],
                    Icons.warning_amber_outlined,
                    Colors.deepOrange,
                    'Lower is better',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDetailQualityBar(double value, Color color) {
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
            Container(
              height: 10,
              width: 280 * value,
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
  
  Widget _buildDetailCard(String title, double value, IconData icon, Color color, String note) {
    final valueColor = value >= 0.6 ? Colors.green.shade400 :
                       value >= 0.4 ? Colors.amber.shade400 :
                       Colors.red.shade400;
                       
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
                color: valueColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRiskCard(String title, double value, IconData icon, Color color, String note) {
    final valueColor = value <= 0.3 ? Colors.green.shade400 :
                       value <= 0.6 ? Colors.amber.shade400 :
                       Colors.red.shade400;
                       
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
                color: valueColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _deleteItem(BuildContext context, String id, WidgetRef ref) async {
    final historyService = ref.read(historyServiceProvider);
    await historyService.deleteHistoryItem(id);
    refreshHistory(ref);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted'),
          backgroundColor: Color(0xFF303030),
        ),
      );
    }
  }
  
  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text(
          'Clear History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear all history? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade300),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final historyService = ref.read(historyServiceProvider);
              await historyService.clearHistory();
              refreshHistory(ref);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History cleared'),
                    backgroundColor: Color(0xFF303030),
                  ),
                );
              }
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
} 