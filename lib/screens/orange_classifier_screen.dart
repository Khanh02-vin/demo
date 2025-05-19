import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/orange_classifier.dart';
import '../models/classification_result.dart';
import '../widgets/enhanced_result_display.dart';
import '../providers/app_provider.dart';

class OrangeClassifierScreen extends ConsumerStatefulWidget {
  const OrangeClassifierScreen({super.key});

  @override
  ConsumerState<OrangeClassifierScreen> createState() => _OrangeClassifierScreenState();
}

class _OrangeClassifierScreenState extends ConsumerState<OrangeClassifierScreen> {
  final OrangeClassifier _classifier = OrangeClassifier();
  final ImagePicker _picker = ImagePicker();
  
  File? _image;
  ClassificationResult? _result;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Preload the models
    _loadModels();
    
    // Restore image if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedImagePath = ref.read(selectedCameraImageProvider);
      if (savedImagePath != null) {
        setState(() {
          _image = File(savedImagePath);
        });
      }
    });
  }
  
  Future<void> _loadModels() async {
    try {
      await _classifier.loadModels();
      debugPrint('Models loaded successfully at app start');
    } catch (e) {
      debugPrint('Error preloading models: $e');
      // We'll try loading again when the user takes a picture
    }
  }
  
  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
        _isLoading = true;
      });
      
      // Save to provider for persistence
      ref.read(selectedCameraImageProvider.notifier).state = pickedFile.path;
      
      // Make sure models are loaded
      try {
        if (!await _modelsAreLoaded()) {
          await _classifier.loadModels();
        }
      } catch (e) {
        debugPrint('Error ensuring models are loaded: $e');
        // Continue anyway and let the classifier handle the error
      }
      
      // Classify the image
      final result = await _classifier.classifyImage(_image!);
      
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }
  
  Future<bool> _modelsAreLoaded() async {
    // A simple dummy check to trigger loadModels if not already loaded
    try {
      final dummyFile = File('dummy_path');
      final result = await _classifier.classifyImage(dummyFile);
      return !result.toString().contains('Failed to load');
    } catch (e) {
      return false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orange Quality Checker'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            if (_image != null)
              Container(
                width: double.infinity,
                height: 300,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing image...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )
            else if (_result != null)
              EnhancedResultDisplay(result: _result!)
          ],
        ),
      ),
    );
  }
} 