import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/services/huggingface_service.dart';
import 'package:met_museum_explorer/services/met_museum_service.dart';
import 'package:met_museum_explorer/services/cache_service.dart';
import 'package:met_museum_explorer/ui/components/ar_info_overlay.dart';
import 'package:met_museum_explorer/ui/screens/details_screen.dart';
import 'package:met_museum_explorer/utils/constants.dart';
import 'package:met_museum_explorer/utils/helpers.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  late final HuggingFaceService _huggingFaceService;
  late final MetMuseumService _metMuseumService;
  late final CacheService _cacheService;
  
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isContinuousScanEnabled = true;
  bool _isModelLoading = true;
  
  Artwork? _currentDetectedArtwork;
  double _detectionConfidence = 0.0;
  
  Timer? _scanTimer;
  int _lastProcessedTimestamp = 0;
  static const int _processingCooldownMs = 3000;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cacheService = CacheService(prefs);
      _metMuseumService = MetMuseumService();
      _huggingFaceService = HuggingFaceService(_cacheService);
      
      await _huggingFaceService.loadModel();
      
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
        _initializeCamera();
      }
    } catch (e) {
      print('Error initializing services: $e');
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error initializing services. Please restart the app.',
          isError: true,
        );
      }
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive) {
      _stopContinuousScan();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          Helpers.showSnackBar(
            context, 
            'No camera found. Please use gallery to select images.',
            isError: true,
          );
        }
        return;
      }
      
      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.medium, // Use medium for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        
        // Start continuous scanning once camera is initialized
        _startContinuousScan();
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        Helpers.showSnackBar(
          context, 
          'Error initializing camera: $e',
          isError: true,
        );
      }
    }
  }
  
  void _startContinuousScan() {
    if (_scanTimer != null) {
      _scanTimer!.cancel();
    }
    
    // Process frames every 500ms
    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isProcessing && _isCameraInitialized && mounted) {
        _processCameraImage();
      }
    });
  }
  
  void _stopContinuousScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }
  
  Future<void> _processCameraImage() async {
    // Check cooldown to prevent processing too many frames
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProcessedTimestamp < _processingCooldownMs) {
      return;
    }
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (_isProcessing) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final imageFile = await _takePictureWithoutSaving();
      if (imageFile != null) {
        await _processImage(imageFile);
      }
    } catch (e) {
      print('Error processing camera frame: $e');
    } finally {
      _lastProcessedTimestamp = DateTime.now().millisecondsSinceEpoch;
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<File?> _takePictureWithoutSaving() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    
    try {
      final XFile photo = await _cameraController!.takePicture();
      return File(photo.path);
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _isContinuousScanEnabled = false;
        _stopContinuousScan();
      });
      _processImage(image);
    }
  }

  Future<void> _processImage(XFile imageFile) async {
    if (_isProcessing || _isModelLoading) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProcessedTimestamp < _processingCooldownMs) return;
    
    setState(() {
      _isProcessing = true;
      _lastProcessedTimestamp = now;
    });
    
    try {
      final File file = File(imageFile.path);
      final artwork = await _huggingFaceService.findMatchingArtwork(file);
      
      if (artwork != null && mounted) {
        setState(() {
          _currentDetectedArtwork = artwork;
          _detectionConfidence = 0.85;
        });
        
        // Navigate to details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(artwork: artwork),
          ),
        );
      } else if (mounted && !_isContinuousScanEnabled) {
        _showNoResultsDialog();
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error processing image. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _viewArtworkDetails() {
    if (_currentDetectedArtwork != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(
            artwork: _currentDetectedArtwork!,
            showARButton: true,
          ),
        ),
      );
    }
  }

  void _showNoResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Match Found'),
        content: const Text('We couldn\'t identify this artwork. Try a different angle or lighting.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isContinuousScanEnabled = true;
              });
              _startContinuousScan();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('An error occurred: $errorMessage'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isContinuousScanEnabled = true;
              });
              _startContinuousScan();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopContinuousScan();
    _cameraController?.dispose();
    _huggingFaceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          _isCameraInitialized
              ? _buildCameraPreview()
              : _isModelLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(child: Text('Initializing camera...')),
          
          // Loading overlay
          if (_isModelLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading AI Model...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing Artwork...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // AR information overlay
          if (_currentDetectedArtwork != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _viewArtworkDetails,
                child: ARInfoOverlay(
                  artwork: _currentDetectedArtwork!,
                  confidence: _detectionConfidence,
                ),
              ),
            ),
            
          // App bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Scan Artwork',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      onPressed: _pickImageFromGallery,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Scanning animation overlay
          if (!_isProcessing && _currentDetectedArtwork == null)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.white.withOpacity(0.8),
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scanning for Artwork...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    
    return Transform.scale(
      scale: _cameraController!.value.aspectRatio / deviceRatio,
      child: Center(
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }
} 