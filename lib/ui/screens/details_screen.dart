import 'package:flutter/material.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/ui/components/ar_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsScreen extends StatelessWidget {
  final Artwork artwork;
  final bool showARButton;

  const DetailsScreen({
    Key? key,
    required this.artwork,
    this.showARButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(artwork.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (artwork.primaryImageUrl != null && artwork.primaryImageUrl!.isNotEmpty)
              Image.network(
                artwork.primaryImageUrl!,
                fit: BoxFit.cover,
                height: 300,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              )
            else
              Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (artwork.artistName != null)
                    Text(
                      artwork.artistName!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.calendar_today, artwork.year?.toString() ?? 'Unknown date'),
                  _infoRow(Icons.category, artwork.department ?? 'Unknown department'),
                  if (artwork.medium != null) _infoRow(Icons.brush, artwork.medium!),
                  if (artwork.culture != null) _infoRow(Icons.public, artwork.culture!),
                  if (artwork.dimensions != null) _infoRow(Icons.straighten, artwork.dimensions!),
                  const SizedBox(height: 16),
                  if (artwork.description != null && artwork.description!.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(artwork.description!),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showARButton)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.view_in_ar),
                          label: const Text('View in AR'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AROverlay(artwork: artwork),
                              ),
                            );
                          },
                        ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('View on Met Website'),
                        onPressed: () async {
                          final url = 'https://www.metmuseum.org/art/collection/search/${artwork.objectId}';
                          if (await canLaunch(url)) {
                            await launch(url);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
} 