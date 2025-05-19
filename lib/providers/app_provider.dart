import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/orange_classifier.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    state = mode;
  }
}

// Scan history provider
final scanHistoryProvider = StateNotifierProvider<ScanHistoryNotifier, List<ScanItem>>((ref) {
  return ScanHistoryNotifier();
});

class ScanItem {
  final String id;
  final String title;
  final DateTime timestamp;
  final String imageUrl;
  final int quality;
  final Map<String, dynamic> data;

  ScanItem({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.imageUrl,
    required this.quality,
    required this.data,
  });

  ScanItem copyWith({
    String? id,
    String? title,
    DateTime? timestamp,
    String? imageUrl,
    int? quality,
    Map<String, dynamic>? data,
  }) {
    return ScanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      quality: quality ?? this.quality,
      data: data ?? this.data,
    );
  }
}

class ScanHistoryNotifier extends StateNotifier<List<ScanItem>> {
  ScanHistoryNotifier() : super([]) {
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    // In a real app, this would load from local storage or database
    // For now, we'll use mock data
    state = [
      ScanItem(
        id: '1',
        title: 'Sample Scan 1',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        imageUrl: 'assets/images/demo1.jpeg',
        quality: 95,
        data: {
          'type': 'orange',
          'predictions': [
            {'class': 'Good Quality', 'confidence': 0.95},
            {'class': 'Orange', 'confidence': 0.98}
          ]
        },
      ),
      ScanItem(
        id: '2',
        title: 'Sample Scan 2',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        imageUrl: 'assets/images/Orange Image.jpeg',
        quality: 85,
        data: {
          'type': 'orange',
          'predictions': [
            {'class': 'Good Quality', 'confidence': 0.85},
            {'class': 'Orange', 'confidence': 0.92}
          ]
        },
      ),
    ];
  }

  void addScan(ScanItem scan) {
    // Create a new list with the scan added (Riverpod requires immutable state)
    state = [...state, scan];
    // In a real app, save to local storage or database
    debugPrint('Scan added: ${scan.id}');
  }

  void removeScan(String id) {
    // Create a new list without the scan to remove
    state = state.where((scan) => scan.id != id).toList();
    // In a real app, update local storage or database
    debugPrint('Scan removed: $id');
  }
}

// TensorFlow model provider
final modelProvider = Provider<TensorFlowService>((ref) {
  return TensorFlowService();
});

class TensorFlowService {
  final OrangeClassifier _classifier = OrangeClassifier();
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel() async {
    try {
      await _classifier.loadModels();
      _isModelLoaded = true;
    } catch (e) {
      debugPrint('Error loading model: $e');
      _isModelLoaded = false;
    }
  }

  Future<Map<String, dynamic>> runInference(String imagePath) async {
    try {
      // Ensure model is loaded before running inference
      if (!_isModelLoaded) {
        debugPrint('Model not loaded, attempting to load now...');
        await loadModel();
        if (!_isModelLoaded) {
          debugPrint('Failed to load model');
          return {
            'predictions': [
              {'class': 'Error', 'confidence': 1.0},
              {'class': 'Failed to load the classification model', 'confidence': 0.0}
            ]
          };
        }
      }
      
      // Make sure file exists before processing
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('Image file not found: $imagePath');
        throw Exception('Image file not found: $imagePath');
      }
      
      debugPrint('Processing image: $imagePath');
      // Use the actual classifier
      final result = await _classifier.classifyImage(imageFile);
      debugPrint('Classification result: $result');
      
      // Handle error cases
      if (!result.isValid) {
        debugPrint('Invalid classification result: ${result.errorMessage}');
        return {
          'predictions': [
            {'class': 'Error', 'confidence': 1.0},
            {'class': result.errorMessage ?? 'Unknown error', 'confidence': 0.0}
          ]
        };
      }
      
      // Format results based on classification
      List<Map<String, dynamic>> predictions = [];
      
      if (result.usedFallback && result.fallbackLabel != null) {
        // If fallback detected a fruit, treat as an orange with the primary classifier
        if (result.fallbackLabel!.toLowerCase() == 'fruit' && (result.fallbackConfidence ?? 0) > 0.4) {
          predictions.add({
            'class': 'Good Quality',
            'confidence': 0.75,
            'note': 'Recognized as generic fruit'
          });
        } else {
          // Add fallback classification as main result
          predictions.add({
            'class': result.fallbackLabel!,
            'confidence': result.fallbackConfidence ?? 0.0
          });
          
          // Add primary classification with lower priority
          predictions.add({
            'class': result.primaryLabel,
            'confidence': result.primaryConfidence,
            'note': 'Low confidence primary result'
          });
        }
      } else {
        // Just use the primary classification
        predictions.add({
          'class': result.primaryLabel,
          'confidence': result.primaryConfidence
        });
      }
      
      return {
        'predictions': predictions,
      };
    } catch (e) {
      debugPrint('Error running inference: $e');
      return {
        'predictions': [
          {'class': 'Error', 'confidence': 1.0},
          {'class': 'Could not process this image: ${e.toString().split('\n')[0]}', 'confidence': 0.0}
        ]
      };
    }
  }

  void dispose() {
    // No need to dispose the interpreter as it's handled by OrangeClassifier
  }
} 