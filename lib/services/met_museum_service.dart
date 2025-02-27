import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/utils/constants.dart';

class MetMuseumService {
  final http.Client _client = http.Client();
  
  Future<List<int>> searchObjects(String query) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/search?q=$query'),
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return List<int>.from(jsonData['objectIDs'] ?? []);
    } else {
      throw Exception('Failed to search objects: ${response.statusCode}');
    }
  }
  
  Future<Artwork> getObjectDetails(int objectId) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/objects/$objectId'),
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Artwork.fromJson(jsonData);
    } else {
      throw Exception('Failed to get object details: ${response.statusCode}');
    }
  }
  
  Future<List<Artwork>> getFeaturedArtworks() async {
    // This would typically call a dedicated endpoint
    // For demo purposes, we'll get a few hardcoded IDs
    final objectIds = [436535, 459055, 437853, 452178, 436282];
    
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
  }
} 