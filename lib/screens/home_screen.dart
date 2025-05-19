import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orange_quality_checker/providers/app_provider.dart';
import 'package:camera/camera.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadTensorFlowModel();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadTensorFlowModel() async {
    try {
      final tensorFlowService = ref.read(modelProvider);
      await tensorFlowService.loadModel();
      
      if (mounted) {
        setState(() {
          _isModelLoaded = tensorFlowService.isModelLoaded;
        });
      }
    } catch (e) {
      debugPrint('Error loading TensorFlow model: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _scanImage() async {
    if (_cameraController == null || !_isCameraInitialized || _isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      // Capture the image
      final image = await _cameraController!.takePicture();
      
      // Process with TensorFlow
      final tensorFlowService = ref.read(modelProvider);
      final result = await tensorFlowService.runInference(image.path);
      
      if (mounted) {
        // Navigate to results page
        context.push('/scan-result', extra: {
          'imagePath': image.path,
          'result': result,
        });
      }
    } catch (e) {
      debugPrint('Error scanning image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          if (!_isModelLoaded)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Load Model',
              onPressed: _loadTensorFlowModel,
            ),
          IconButton(
            icon: const Icon(Icons.agriculture),
            tooltip: 'Orange Classifier',
            onPressed: () => context.push('/orange-classifier'),
          ),
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Test ML Model',
            onPressed: () => context.push('/model-test'),
          ),
        ],
      ),
      body: _isCameraInitialized 
          ? _buildCameraPreview() 
          : _buildLoadingView(),
      floatingActionButton: _isCameraInitialized && !_isScanning
          ? FloatingActionButton(
              onPressed: _scanImage,
              tooltip: 'Scan',
              backgroundColor: _isModelLoaded ? null : Colors.grey,
              child: const Icon(Icons.camera),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        if (!_isModelLoaded)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red.withOpacity(0.7),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Model not loaded. Results may be incorrect.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        if (_isScanning)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing camera...'),
        ],
      ),
    );
  }
} 