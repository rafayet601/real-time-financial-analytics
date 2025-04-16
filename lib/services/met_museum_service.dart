import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/utils/constants.dart';

class MetMuseumService {
  final http.Client _client = http.Client();
  
  Future<List<int>> searchObjects(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/search?q=$query'),
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return List<int>.from(jsonData['objectIDs'] ?? []);
      } else {
        throw Exception('Failed to search objects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching objects: $e');
      rethrow;
    }
  }
  
  Future<Artwork> getObjectDetails(int objectId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/objects/$objectId'),
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Artwork.fromJson(jsonData);
      } else {
        throw Exception('Failed to get object details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting object details: $e');
      rethrow;
    }
  }
  
  Future<List<Artwork>> getFeaturedArtworks() async {
    try {
      // These are some notable artworks from the MET collection
      final objectIds = [
        436535, // Starry Night
        459055, // The Great Wave
        437853, // Washington Crossing the Delaware
        452178, // The Thinker
        436282, // The Scream
        436105, // The Persistence of Memory
        436524, // The Birth of Venus
        437430, // The Last Supper
        436528, // Mona Lisa
        436527, // The Night Watch
      ];
      
      List<Artwork> artworks = [];
      for (final id in objectIds) {
        try {
          final artwork = await getObjectDetails(id);
          artworks.add(artwork);
        } catch (e) {
          print('Error fetching artwork $id: $e');
        }
      }
      
      return artworks;
    } catch (e) {
      print('Error getting featured artworks: $e');
      rethrow;
    }
  }
  
  void dispose() {
    _client.close();
  }
} 