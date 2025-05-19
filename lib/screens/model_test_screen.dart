import 'dart:io';
import 'package:flutter/material.dart';
import '../services/orange_classifier.dart';
import 'package:image_picker/image_picker.dart';
import '../models/classification_result.dart';

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  State<ModelTestScreen> createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  bool _isLoading = false;
  File? _imageFile;
  ClassificationResult? _classificationResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Orange Quality Checker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Image display area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 100,
                                    color: Colors.grey[400],
                                  ),
                                ),
                    ),
                  ),
                  
                  // Results area
                  if (_classificationResult != null) ...[
                    const SizedBox(height: 20),
                    _buildClassificationResultCard(),
                  ],
                ],
              ),
            ),
          ),
          
          // Button area at the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 48.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed: () => _getImage(ImageSource.camera),
                  color: Colors.purple[200]!,
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed: () => _getImage(ImageSource.gallery),
                  color: Colors.purple[200]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black54,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationResultCard() {
    if (_classificationResult == null) return const SizedBox.shrink();
    
    final result = _classificationResult!;
    final isGood = result.primaryLabel.toLowerCase().contains('good');
    
    Color backgroundColor = isGood ? Colors.green[100]! : Colors.red[100]!;
    
    // If there was an error, use yellow background
    if (!result.isValid) {
      backgroundColor = Colors.yellow[100]!;
    }
    
    // If using fallback, adjust color to be slightly different
    if (result.usedFallback) {
      backgroundColor = isGood ? Colors.green[50]! : Colors.orange[100]!;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.usedFallback ? Colors.orange : Colors.grey[400]!,
          width: result.usedFallback ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Add an icon based on the classification
              Icon(
                isGood ? Icons.check_circle : Icons.cancel,
                color: isGood ? Colors.green[700] : Colors.red[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Classification: ${result.primaryLabel}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Confidence bar with color gradient
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confidence: ${(result.primaryConfidence * 100).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.primaryConfidence,
                  backgroundColor: Colors.grey[300],
                  minHeight: 8,
                  color: _getConfidenceColor(result.primaryConfidence),
                ),
              ),
            ],
          ),
          
          // Show fallback information if used
          if (result.usedFallback && result.fallbackLabel != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Using Fallback Classification:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fallback Label: ${result.fallbackLabel}',
              style: const TextStyle(fontSize: 14),
            ),
            if (result.fallbackConfidence != null) ...[
              const SizedBox(height: 4),
              Text(
                'Fallback Confidence: ${(result.fallbackConfidence! * 100).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
          
          // Show details if available
          if (result.details != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              'Analysis Details:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.details!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence < 0.3) return Colors.red;
    if (confidence < 0.6) return Colors.orange;
    if (confidence < 0.8) return Colors.amber;
    return Colors.green;
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
          _imageFile = File(pickedFile.path);
          _classificationResult = null;
        });
        
        // Process the image
        await _classifyImage();
      }
    } catch (e) {
      _showErrorSnackbar("Failed to pick image: $e");
    }
  }
  
  Future<void> _classifyImage() async {
    if (_imageFile == null) return;
    
    try {
      // Initialize classifier and classify
      final classifier = OrangeClassifier();
      await classifier.loadModels();
      final result = await classifier.classifyImage(_imageFile!);
      
      setState(() {
        _classificationResult = result;
        _isLoading = false;
      });
      
      // Cleanup
      classifier.dispose();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar("Error classifying image: $e");
    }
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
} 