import 'package:flutter/material.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/services/met_museum_service.dart';
import 'package:met_museum_explorer/ui/screens/scanner_screen.dart';
import 'package:met_museum_explorer/ui/screens/details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MetMuseumService _metMuseumService = MetMuseumService();
  List<Artwork>? _featuredArtworks;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFeaturedArtworks();
  }

  Future<void> _loadFeaturedArtworks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final artworks = await _metMuseumService.getFeaturedArtworks();
      setState(() {
        _featuredArtworks = artworks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artworks: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Met Museum Explorer'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search for artworks...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _featuredArtworks == null || _featuredArtworks!.isEmpty
                    ? const Center(child: Text('No artworks found'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _featuredArtworks!.length,
                        itemBuilder: (context, index) {
                          final artwork = _featuredArtworks![index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailsScreen(artwork: artwork),
                                ),
                              );
                            },
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: artwork.primaryImageUrl != null &&
                                            artwork.primaryImageUrl!.isNotEmpty
                                        ? Image.network(
                                            artwork.primaryImageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(Icons.image_not_supported),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                          )
                                        : const Center(
                                            child: Icon(Icons.image_not_supported),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artwork.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (artwork.artistName != null)
                                          Text(
                                            artwork.artistName!,
                                            style: TextStyle(color: Colors.grey[600]),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
} 