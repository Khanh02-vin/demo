import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/orange_classifier.dart';
import '../models/classification_result.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class TestDataScreen extends StatefulWidget {
  const TestDataScreen({super.key});

  @override
  State<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends State<TestDataScreen> {
  bool _isLoading = true;
  File? _selectedImage;
  ClassificationResult? _classificationResult;
  List<String> _testImages = [];
  final OrangeClassifier _classifier = OrangeClassifier();
  
  @override
  void initState() {
    super.initState();
    _loadClassifier();
    _loadTestImages();
  }
  
  Future<void> _loadClassifier() async {
    try {
      await _classifier.loadModels();
    } catch (e) {
      _showErrorSnackbar("Error loading model: $e");
    }
  }
  
  Future<void> _loadTestImages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // For assets in subdirectories, it's better to use direct file paths
      final List<String> testImagePaths = [];
      
      // Attempt to list test files programmatically first
      try {
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = Map.from(json.decode(manifestContent));
        
        // Use the correct folder paths that match your project structure
        const String goodOrangesPath = 'assets/images/old_oranges_data/test_set/Orange_Good';
        const String badOrangesPath = 'assets/images/old_oranges_data/test_set/Orange_Bad';
        
        // Filter the paths to include only image files from both test folders
        testImagePaths.addAll(
          manifestMap.keys
            .where((String key) => 
                (key.startsWith(goodOrangesPath) || key.startsWith(badOrangesPath)) && 
                (key.toLowerCase().endsWith('.jpg') || 
                key.toLowerCase().endsWith('.jpeg') || 
                key.toLowerCase().endsWith('.png')))
            .toList()
        );
        
        debugPrint('Found ${testImagePaths.length} test images from assets');
      } catch (e) {
        debugPrint('Error loading from asset manifest: $e');
        // If there's an error, we'll try with hardcoded paths below
      }
      
      // If the programmatic method failed or found no images, use hardcoded paths as fallback
      if (testImagePaths.isEmpty) {
        debugPrint('Using fallback method for test images');
        
        // Add some hardcoded image paths from both good and bad orange folders
        final goodBasePath = 'assets/images/old_oranges_data/test_set/Orange_Good';
        final badBasePath = 'assets/images/old_oranges_data/test_set/Orange_Bad';
        
        // Try to add a few images from both categories
        for (int i = 1; i <= 10; i++) {
          // Note: This assumes files are named consistently, adjust if needed
          testImagePaths.add('$goodBasePath/orange_good_$i.jpg');
          testImagePaths.add('$badBasePath/orange_bad_$i.jpg');
        }
      }
      
      setState(() {
        _testImages = testImagePaths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar("Error loading test images: $e");
    }
  }
  
  Future<void> _selectAndClassifyImage(String assetPath) async {
    setState(() {
      _isLoading = true;
      _classificationResult = null;
    });
    
    try {
      debugPrint('Attempting to load asset: $assetPath');
      
      // Check if asset exists first
      try {
        await rootBundle.load(assetPath);
        debugPrint('Asset successfully loaded');
      } catch (e) {
        debugPrint('Asset not found: $e');
        throw Exception('The asset does not exist: $assetPath');
      }
      
      // First, copy the asset to a temporary file so we can use File class
      final tempDir = await getTemporaryDirectory();
      final filename = assetPath.split('/').last;
      final tempFile = File('${tempDir.path}/$filename');
      
      try {
        final imageData = await rootBundle.load(assetPath);
        final bytes = imageData.buffer.asUint8List();
        await tempFile.writeAsBytes(bytes);
        debugPrint('Asset successfully copied to temp file: ${tempFile.path}');
      } catch (e) {
        debugPrint('Error copying asset to temp file: $e');
        throw Exception('Failed to copy asset to temporary file: $e');
      }
      
      // Verify the temp file exists and has data
      if (!tempFile.existsSync()) {
        throw Exception('Temporary file was not created');
      }
      
      if (tempFile.lengthSync() == 0) {
        throw Exception('Temporary file is empty');
      }
      
      // Classify the image
      final result = await _classifier.classifyImage(tempFile);
      
      setState(() {
        _selectedImage = tempFile;
        _classificationResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar("Error classifying image: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Data Images'),
        elevation: 0,
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Images',
            onPressed: _loadTestImages,
          ),
          // Add a folder browser button
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Show Folder Structure',
            onPressed: _showAssetFolderStructure,
          ),
        ],
      ),
      body: _isLoading && _testImages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // If an image is selected, show it with results
                if (_selectedImage != null) ...[
                  Container(
                    height: 250,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  // Show classification results
                  if (_classificationResult != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildClassificationResultCard(),
                    ),
                    const Divider(),
                  ],
                ],
                
                // Grid of test images
                Expanded(
                  child: _testImages.isEmpty
                      ? const Center(child: Text('No test images found in the specified directory'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _testImages.length,
                          itemBuilder: (context, index) {
                            final imagePath = _testImages[index];
                            return InkWell(
                              onTap: () => _selectAndClassifyImage(imagePath),
                              child: Card(
                                elevation: 4,
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      alignment: Alignment.bottomCenter,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Show quality badge
                                          if (imagePath.contains('Orange_Good'))
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'GOOD',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          else if (imagePath.contains('Orange_Bad'))
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'BAD',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            imagePath.split('/').last,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
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
          
          // Confidence bar
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
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showAssetFolderStructure() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map.from(json.decode(manifestContent));
      
      // Get all asset paths
      final List<String> assetPaths = manifestMap.keys.toList();
      
      // Filter to only show image assets
      final List<String> imageAssets = assetPaths
          .where((path) => 
              path.toLowerCase().endsWith('.jpg') || 
              path.toLowerCase().endsWith('.jpeg') || 
              path.toLowerCase().endsWith('.png'))
          .toList();
      
      // Group by folders for better presentation
      final Map<String, List<String>> folderStructure = {};
      
      for (final asset in imageAssets) {
        final parts = asset.split('/');
        if (parts.length > 1) {
          final folder = parts.sublist(0, parts.length - 1).join('/');
          folderStructure[folder] = (folderStructure[folder] ?? [])..add(parts.last);
        }
      }
      
      // Show dialog with folder structure
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Asset Folder Structure'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...folderStructure.entries.map((entry) {
                  return ExpansionTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    children: [
                      ...entry.value.map((filename) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            filename,
                            style: const TextStyle(fontSize: 13),
                          ),
                          leading: const Icon(Icons.image, size: 18),
                          onTap: () {
                            Navigator.pop(context);
                            _selectAndClassifyImage('${entry.key}/$filename');
                          },
                        );
                      }),
                    ],
                  );
                }),
                if (folderStructure.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No image assets found.'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackbar("Error loading asset structure: $e");
    }
  }
  
  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
} 