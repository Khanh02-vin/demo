import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orange_quality_checker/providers/app_provider.dart';
import 'dart:io';

class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({super.key});

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  String? imagePath;
  Map<String, dynamic>? result;
  bool isSaved = false;
  String title = 'New Scan';
  late final TextEditingController _titleController;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: title);
    Future.microtask(() {
      if (!mounted) return;
      final params = GoRouterState.of(context).extra as Map<String, dynamic>?;
      
      if (params != null) {
        setState(() {
          imagePath = params['imagePath'] as String;
          result = params['result'] as Map<String, dynamic>;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mounted = false;
    super.dispose();
  }

  void _saveScan() {
    if (imagePath == null || result == null) return;
    
    final scanHistoryNotifier = ref.read(scanHistoryProvider.notifier);
    
    // Generate a unique ID (use a UUID package in a real app)
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create a new scan item
    final scanItem = ScanItem(
      id: id,
      title: title,
      timestamp: DateTime.now(),
      imageUrl: imagePath!, // In a real app, you'd save this to permanent storage
      quality: 90, // Mock quality
      data: result!,
    );
    
    // Add the scan to history
    scanHistoryNotifier.addScan(scanItem);
    
    setState(() {
      isSaved = true;
    });
    
    // Show a success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan saved to history')),
      );
      
      // Navigate to history screen after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.go('/history');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.check : Icons.save),
            onPressed: isSaved ? null : _saveScan,
            tooltip: 'Save Scan',
          ),
        ],
      ),
      body: imagePath != null && result != null ? _buildResults() : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildResults() {
    if (imagePath == null || result == null) {
      return _buildLoading();
    }
    
    return Column(
      children: [
        // Image preview
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Image.file(
            File(imagePath!),
            fit: BoxFit.contain,
          ),
        ),
        
        // Title text field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            controller: _titleController,
            onChanged: (value) {
              setState(() {
                title = value;
              });
            },
          ),
        ),
        
        // Results section
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildResultsList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    if (result == null || !result!.containsKey('predictions')) {
      return const Center(child: Text('No prediction data available'));
    }
    
    final predictions = result!['predictions'] as List<dynamic>;
    
    if (predictions.isEmpty) {
      return const Center(child: Text('No predictions found'));
    }
    
    // Check for error or "Not an Orange" cases
    if (predictions.isNotEmpty) {
      final firstPrediction = predictions[0] as Map<String, dynamic>;
      final className = firstPrediction['class'] as String;
      
      if (className == 'Error' || className == 'Not an Orange') {
        // This is an error case or non-orange image
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              className == 'Error' ? Icons.error_outline : Icons.help_outline,
              size: 64,
              color: className == 'Error' ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              className,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (predictions.length > 1) 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  predictions[1]['class'] as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Try scanning a different image',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        );
      }
    }
    
    // Normal case - display all predictions
    return ListView.builder(
      itemCount: predictions.length,
      itemBuilder: (context, index) {
        final prediction = predictions[index] as Map<String, dynamic>;
        final className = prediction['class'] as String;
        final confidence = prediction['confidence'] as double;
        
        // Determine color based on confidence
        Color confidenceColor;
        if (confidence > 0.7) {
          confidenceColor = Colors.green;
        } else if (confidence > 0.4) {
          confidenceColor = Colors.orange;
        } else {
          confidenceColor = Colors.red;
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            title: Text(
              className,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
            trailing: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: confidence,
                    backgroundColor: Colors.grey.withAlpha(51),
                    valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                  ),
                  Text(
                    '${(confidence * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 