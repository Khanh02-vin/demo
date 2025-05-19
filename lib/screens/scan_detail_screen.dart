import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orange_quality_checker/providers/app_provider.dart';
import 'package:intl/intl.dart';

class ScanDetailScreen extends ConsumerWidget {
  final String scanId;
  
  const ScanDetailScreen({super.key, required this.scanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scans = ref.watch(scanHistoryProvider);
    final scan = scans.firstWhere(
      (scan) => scan.id == scanId,
      orElse: () => ScanItem(
        id: '0',
        title: 'Not Found',
        timestamp: DateTime.now(),
        imageUrl: '',
        quality: 0,
        data: {},
      ),
    );
    
    final theme = Theme.of(context);
    
    if (scan.id == '0') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Details'),
          backgroundColor: theme.colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('Scan not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(scan.title),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Image.asset(
                scan.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            
            // Metadata
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.yMMMd().add_jm().format(scan.timestamp),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildQualityIndicator(scan.quality, theme),
                  const SizedBox(height: 24),
                  
                  // Scan Data Section
                  Text(
                    'Scan Results',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildDataSection(scan.data, theme),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Actions',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, scan, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQualityIndicator(int quality, ThemeData theme) {
    Color color;
    String label;
    
    if (quality >= 90) {
      color = Colors.green;
      label = 'Excellent Quality';
    } else if (quality >= 70) {
      color = Colors.blue;
      label = 'Good Quality';
    } else if (quality >= 50) {
      color = Colors.orange;
      label = 'Fair Quality';
    } else {
      color = Colors.red;
      label = 'Poor Quality';
    }
    
    return Row(
      children: [
        Icon(
          Icons.high_quality,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDataSection(Map<String, dynamic> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Text('No data available');
    }
    
    // Check if there are predictions in the data
    if (data.containsKey('predictions') && data['predictions'] is List) {
      final predictions = data['predictions'] as List;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...predictions.map((prediction) {
            final predictionMap = prediction as Map<String, dynamic>;
            final className = predictionMap['class'] as String;
            final confidence = predictionMap['confidence'] as double;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: confidence,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      strokeWidth: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }
    
    // Generic data display
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, ScanItem scan, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Share'),
          onPressed: () {
            // Share functionality would go here in a real app
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sharing not implemented in demo')),
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          onPressed: () {
            _showDeleteConfirmation(context, scan, ref);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, ScanItem scan, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: Text('Are you sure you want to delete "${scan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete the scan
              ref.read(scanHistoryProvider.notifier).removeScan(scan.id);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 