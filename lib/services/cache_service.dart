import 'dart:convert';
import 'package:shared_preferences.dart';
import 'package:met_museum_explorer/models/artwork.dart';

class CacheService {
  static const String _artworksKey = 'cached_artworks';
  static const String _recognitionCacheKey = 'recognition_cache';
  static const Duration _cacheDuration = Duration(days: 1);
  
  final SharedPreferences _prefs;
  
  CacheService(this._prefs);
  
  Future<List<Artwork>> getCachedArtworks() async {
    final cachedData = _prefs.getString(_artworksKey);
    if (cachedData == null) return [];
    
    try {
      final List<dynamic> jsonList = json.decode(cachedData);
      return jsonList.map((json) => Artwork.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing cached artworks: $e');
      return [];
    }
  }
  
  Future<void> cacheArtworks(List<Artwork> artworks) async {
    try {
      final jsonList = artworks.map((art) => art.toJson()).toList();
      await _prefs.setString(_artworksKey, json.encode(jsonList));
    } catch (e) {
      print('Error caching artworks: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getCachedRecognition(String imageHash) async {
    final cache = _prefs.getString(_recognitionCacheKey);
    if (cache == null) return null;
    
    try {
      final Map<String, dynamic> cacheMap = json.decode(cache);
      final cachedResult = cacheMap[imageHash];
      
      if (cachedResult != null) {
        final timestamp = DateTime.parse(cachedResult['timestamp']);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return cachedResult['result'];
        }
      }
    } catch (e) {
      print('Error reading recognition cache: $e');
    }
    return null;
  }
  
  Future<void> cacheRecognition(String imageHash, dynamic result) async {
    try {
      final cache = _prefs.getString(_recognitionCacheKey) ?? '{}';
      final Map<String, dynamic> cacheMap = json.decode(cache);
      
      cacheMap[imageHash] = {
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _prefs.setString(_recognitionCacheKey, json.encode(cacheMap));
    } catch (e) {
      print('Error caching recognition result: $e');
    }
  }
  
  Future<void> clearCache() async {
    await _prefs.remove(_artworksKey);
    await _prefs.remove(_recognitionCacheKey);
  }
} 