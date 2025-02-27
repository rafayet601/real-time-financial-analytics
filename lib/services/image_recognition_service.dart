import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';

class ImageRecognitionService {
  bool _isModelLoaded = false;
  
  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: 'assets/ml/artwork_model.tflite',
        labels: 'assets/ml/artwork_labels.txt',
      );
      _isModelLoaded = true;
      print('TFLite model loaded successfully');
    } on PlatformException catch (e) {
      print('Failed to load model: ${e.message}');
      _isModelLoaded = false;
    }
  }
  
  Future<List<dynamic>?> recognizeImage(File image) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    
    try {
      final recognition = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 5,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );
      
      return recognition;
    } catch (e) {
      print('Error recognizing image: $e');
      return null;
    }
  }
  
  Future<void> dispose() async {
    await Tflite.close();
    _isModelLoaded = false;
  }
} 