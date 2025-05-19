import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class ModelDetailsScreen extends ConsumerWidget {
  final String modelId;

  const ModelDetailsScreen({super.key, required this.modelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, this would fetch the model details from a provider
    // For now, we'll use mock data
    final modelDetails = _getMockModelDetails(modelId);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(modelDetails['name'] as String),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.model_training,
                    size: 40,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelDetails['name'] as String,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version: ${modelDetails['version']}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      _buildModelStatusChip(
                        modelDetails['status'] as String,
                        theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Model stats
            Text(
              'Model Statistics',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatsCard(modelDetails, theme),
            
            const SizedBox(height: 24),
            
            // Performance graph
            Text(
              'Performance',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildPerformanceChart(theme),
            ),
            
            const SizedBox(height: 24),
            
            // Model description
            Text(
              'Description',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              modelDetails['description'] as String,
              style: theme.textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 24),
            
            // Model parameters
            Text(
              'Parameters',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildParametersTable(
              (modelDetails['parameters'] as Map<String, dynamic>),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStatusChip(String status, ThemeData theme) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'training':
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case 'deprecated':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> modelDetails, ThemeData theme) {
    final stats = modelDetails['stats'] as Map<String, dynamic>;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Accuracy',
              '${stats['accuracy']}%',
              Icons.auto_graph,
              theme,
            ),
            _buildStatItem(
              'Size',
              stats['size'] as String,
              Icons.sd_storage,
              theme,
            ),
            _buildStatItem(
              'Speed',
              stats['speed'] as String,
              Icons.speed,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(ThemeData theme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: theme.dividerColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('${value.toInt()}'),
                );
              },
              interval: 2,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('${value.toInt()}'),
                );
              },
              interval: 20,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.dividerColor),
        ),
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // Accuracy line
          LineChartBarData(
            spots: const [
              FlSpot(0, 30),
              FlSpot(2, 45),
              FlSpot(4, 60),
              FlSpot(6, 75),
              FlSpot(8, 85),
              FlSpot(10, 90),
            ],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
          // Precision line
          LineChartBarData(
            spots: const [
              FlSpot(0, 40),
              FlSpot(2, 50),
              FlSpot(4, 65),
              FlSpot(6, 70),
              FlSpot(8, 80),
              FlSpot(10, 85),
            ],
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersTable(Map<String, dynamic> parameters, ThemeData theme) {
    return Table(
      border: TableBorder.all(
        color: theme.dividerColor,
        width: 1,
        style: BorderStyle.solid,
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Parameter',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Value',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        ...parameters.entries.map((entry) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(entry.key),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(entry.value.toString()),
              ),
            ],
          );
        }),
      ],
    );
  }

  Map<String, dynamic> _getMockModelDetails(String modelId) {
    // In a real app, this would fetch from a provider or service
    return {
      'id': modelId,
      'name': 'TensorFlow Model $modelId',
      'version': '1.0.3',
      'status': 'Active',
      'description': 'This model is designed for object recognition and classification. '
          'It uses a convolutional neural network architecture to identify objects in images '
          'with high accuracy. The model has been trained on a diverse dataset of common '
          'objects and can recognize over 1,000 different categories.',
      'stats': {
        'accuracy': 92,
        'size': '4.2 MB',
        'speed': '150ms',
      },
      'parameters': {
        'learning_rate': '0.001',
        'batch_size': '32',
        'epochs': '100',
        'optimizer': 'Adam',
        'loss_function': 'Categorical Cross-Entropy',
      },
    };
  }
} 