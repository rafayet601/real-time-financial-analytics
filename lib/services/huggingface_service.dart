import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:transformers/transformers.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/services/met_museum_service.dart';
import 'package:met_museum_explorer/services/cache_service.dart';
import 'package:crypto/crypto.dart';

class HuggingFaceService {
  static const String _modelName = 'openai/clip-vit-base-patch32';
  late TransformersPipeline _pipeline;
  bool _isModelLoaded = false;
  final MetMuseumService _metMuseumService = MetMuseumService();
  final CacheService _cacheService;
  
  HuggingFaceService(this._cacheService);
  
  Future<void> loadModel() async {
    try {
      _pipeline = await TransformersPipeline.fromPretrained(
        _modelName,
        task: 'zero-shot-image-classification',
      );
      _isModelLoaded = true;
      print('Hugging Face model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
      _isModelLoaded = false;
    }
  }
  
  String _generateImageHash(File image) {
    final bytes = image.readAsBytesSync();
    return sha256.convert(bytes).toString();
  }
  
  Future<List<dynamic>?> recognizeImage(File image, List<String> labels) async {
    if (!_isModelLoaded) {
      await loadModel();
    }
    
    final imageHash = _generateImageHash(image);
    final cachedResult = await _cacheService.getCachedRecognition(imageHash);
    if (cachedResult != null) {
      return List<dynamic>.from(cachedResult['results']);
    }
    
    try {
      final result = await FlutterIsolate.run(() async {
        final pipeline = await TransformersPipeline.fromPretrained(
          _modelName,
          task: 'zero-shot-image-classification',
        );
        
        final output = await pipeline(
          image.path,
          candidateLabels: labels,
        );
        
        return output;
      });
      
      if (result != null) {
        await _cacheService.cacheRecognition(imageHash, {'results': result});
      }
      
      return result;
    } catch (e) {
      print('Error recognizing image: $e');
      return null;
    }
  }
  
  Future<Artwork?> findMatchingArtwork(File image) async {
    try {
      // Try to get cached artworks first
      List<Artwork> artworks = await _cacheService.getCachedArtworks();
      
      // If no cached artworks, fetch from API
      if (artworks.isEmpty) {
        artworks = await _metMuseumService.getFeaturedArtworks();
        await _cacheService.cacheArtworks(artworks);
      }
      
      final artworkTitles = artworks.map((art) => art.title).toList();
      final artworkArtists = artworks.map((art) => art.artistDisplayName ?? '').toList();
      final artworkDepartments = artworks.map((art) => art.department ?? '').toList();
      
      // Create a comprehensive list of labels
      final labels = [
        ...artworkTitles,
        ...artworkArtists.where((artist) => artist.isNotEmpty),
        ...artworkDepartments.where((dept) => dept.isNotEmpty),
        'painting',
        'sculpture',
        'photograph',
        'drawing',
        'print',
        'textile',
        'ceramic',
        'metalwork',
        'portrait',
        'landscape',
        'still life',
        'abstract',
        'modern art',
        'contemporary art',
        'classical art',
        'renaissance',
        'baroque',
        'impressionism',
        'expressionism',
      ];
      
      final results = await recognizeImage(image, labels);
      
      if (results != null && results.isNotEmpty) {
        // Get the top matches
        final topMatches = results.take(3).toList();
        
        // Find the best matching artwork
        for (final match in topMatches) {
          final matchedLabel = match['label'].toString().toLowerCase();
          
          // Try to match with artwork title
          final matchingArtwork = artworks.firstWhere(
            (art) => art.title.toLowerCase().contains(matchedLabel) ||
                    (art.artistDisplayName?.toLowerCase().contains(matchedLabel) ?? false) ||
                    (art.department?.toLowerCase().contains(matchedLabel) ?? false),
            orElse: () => artworks[0],
          );
          
          // If we found a good match, return it
          if (matchingArtwork != artworks[0]) {
            return matchingArtwork;
          }
        }
        
        // If no specific match found, return the first artwork
        return artworks[0];
      }
      
      return null;
    } catch (e) {
      print('Error finding matching artwork: $e');
      return null;
    }
  }
  
  Future<void> dispose() async {
    _isModelLoaded = false;
  }
} 