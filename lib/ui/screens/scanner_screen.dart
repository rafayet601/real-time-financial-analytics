import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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
import 'package:provider/provider.dart';
import 'package:met_museum_explorer/services/ml_service.dart';

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
  
  MLService get _mlService => Provider.of<MLService>(context, listen: false);
  MetMuseumService get _metService => Provider.of<MetMuseumService>(context, listen: false);
  
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
        _startScanning();
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
  
  void _startScanning() {
    _scanTimer?.cancel(); // Cancel any existing timer
    // Scan every few seconds (adjust interval as needed)
    _scanTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isProcessing && _isCameraInitialized && _cameraController!.value.isStreamingImages == false) {
          _scanImage();
      }
    });
  }
  
  void _stopContinuousScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }
  
  Future<void> _scanImage() async {
    if (!_isCameraInitialized || _cameraController == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      final recognitionResults = await _mlService.recognizeImage(imageBytes);

      if (recognitionResults != null && recognitionResults.isNotEmpty) {
        // Find the result with the highest confidence
        final topResult = recognitionResults.entries.reduce((a, b) => a.value > b.value ? a : b);
        final artworkLabel = topResult.key;
        final confidence = topResult.value;

        print('Top Result: $artworkLabel with confidence: $confidence');

        if (confidence > AppConstants.minConfidenceThreshold) {
           // Assuming the label directly corresponds to an object ID or requires mapping
          // For now, let's assume the label IS the object ID (needs adjustment)
          try {
            final objectId = int.parse(artworkLabel);
            final artwork = await _metService.getObjectDetails(objectId);
            setState(() {
              _currentDetectedArtwork = artwork;
              _detectionConfidence = confidence;
            });
             // Optionally stop scanning or navigate
             // _scanTimer?.cancel();
             // _navigateToDetails(artwork);
          } catch (e) {
             print('Failed to parse label or fetch artwork: $e');
             setState(() {
              _currentDetectedArtwork = null; // Clear previous detection if fetch fails
              _detectionConfidence = 0.0;
            });
          }
        } else {
           setState(() {
              _currentDetectedArtwork = null;
              _detectionConfidence = 0.0;
            });
        }
      } else {
         setState(() {
            _currentDetectedArtwork = null;
            _detectionConfidence = 0.0;
          });
      }
    } on CameraException catch (e) {
      print('Error taking picture: ${e.description}');
    } catch (e) {
      print('Error during scanning: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
     _scanTimer?.cancel(); // Stop scanning when picking from gallery
     setState(() => _isProcessing = true);
     try {
       final picker = ImagePicker();
       final pickedFile = await picker.pickImage(source: ImageSource.gallery);
       if (pickedFile != null) {
         final imageBytes = await pickedFile.readAsBytes();
         // Process the picked image similar to _scanImage
         final recognitionResults = await _mlService.recognizeImage(imageBytes);
          if (recognitionResults != null && recognitionResults.isNotEmpty) {
            final topResult = recognitionResults.entries.reduce((a, b) => a.value > b.value ? a : b);
            final artworkLabel = topResult.key;
            final confidence = topResult.value;
             if (confidence > AppConstants.minConfidenceThreshold) {
              try {
                 final objectId = int.parse(artworkLabel);
                 final artwork = await _metService.getObjectDetails(objectId);
                 _navigateToDetails(artwork);
               } catch (e) {
                 _showError('Could not find details for the recognized artwork.');
               }
             } else {
               _showError('Artwork not recognized with sufficient confidence.');
             }
           } else {
             _showError('Could not recognize artwork in the selected image.');
           }
       }
     } catch (e) {
       _showError('Failed to pick image: $e');
     } finally {
        setState(() => _isProcessing = false);
        _startScanning(); // Resume scanning
     }
  }

  void _navigateToDetails(Artwork artwork) {
     _scanTimer?.cancel(); // Stop scanning before navigating
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          artwork: artwork,
          showARButton: AppConstants.enableAR, // Use constant from AppConstants
        ),
      ),
    ).then((_) => _startScanning()); // Resume scanning when returning
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                onTap: () => _navigateToDetails(_currentDetectedArtwork!),
                child: ARInfoOverlay(
                  artwork: _currentDetectedArtwork!,
                  confidence: _detectionConfidence,
                  showARButton: false,
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
          
          // Demo mode indicator
          if (ApiConstants.DEMO_MODE)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: const Text(
                  'DEMO MODE: Point camera at any artwork to see sample data',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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