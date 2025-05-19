import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:orange_quality_checker/services/orange_classifier.dart';

// A simple script to test classification on a directory of images
// To run: flutter run -d <device_id> test_classification.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MaterialApp(
    home: ClassificationTestApp(),
  ));
}

class ClassificationTestApp extends StatefulWidget {
  const ClassificationTestApp({super.key});

  @override
  State<ClassificationTestApp> createState() => _ClassificationTestAppState();
}

class _ClassificationTestAppState extends State<ClassificationTestApp> {
  final OrangeClassifier _classifier = OrangeClassifier();
  final List<String> _log = [];
  bool _isLoading = true;
  String _status = 'Initializing...';
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      setState(() {
        _status = 'Loading model...';
      });
      
      await _classifier.loadModels();
      _addLog('Model loaded successfully');
      
      setState(() {
        _status = 'Ready to test';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('Error initializing: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  
  void _addLog(String message) {
    setState(() {
      _log.add(message);
    });
  }
  
  Future<void> _pickAndClassifyImage() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Selecting image...';
      });
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final imagePath = result.files.first.path;
        final imageFile = File(imagePath);
        
        setState(() {
          _status = 'Classifying image...';
        });
        
        final startTime = DateTime.now();
        final classification = await _classifier.classifyImage(imageFile);
        final endTime = DateTime.now();
        final processingTime = endTime.difference(startTime).inMilliseconds;
        
        _addLog('Image: ${path.basename(imagePath)}');
        _addLog('Classification: ${classification.primaryLabel}');
        _addLog('Confidence: ${(classification.primaryConfidence * 100).toStringAsFixed(2)}%');
        if (classification.details != null) {
          _addLog('Details: ${classification.details}');
        }
        _addLog('Processing time: $processingTime ms');
        _addLog('--------------------');
      } else {
        _addLog('No image selected');
      }
    } catch (e) {
      _addLog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _status = 'Ready to test';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orange Classifier Test'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                if (!_isLoading)
                  ElevatedButton(
                    onPressed: _pickAndClassifyImage,
                    child: const Text('Test Image'),
                  ),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length,
              itemBuilder: (context, index) {
                return Text(
                  _log[index],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}

// File picker to use in the app
class FilePicker {
  static final FilePicker platform = FilePicker();
  
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    bool allowMultiple = false,
  }) async {
    try {
      return FilePickerResult([
        FilePickerResultItem('/path/to/image.jpg'),
      ]);
    } catch (e) {
      return null;
    }
  }
}

class FilePickerResult {
  final List<FilePickerResultItem> files;
  
  FilePickerResult(this.files);
}

class FilePickerResultItem {
  final String path;
  
  FilePickerResultItem(this.path);
}

enum FileType {
  any,
  image,
} 