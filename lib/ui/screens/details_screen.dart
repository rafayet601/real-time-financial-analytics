import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/utils/constants.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: artwork.primaryImage != null
                  ? CachedNetworkImage(
                      imageUrl: artwork.primaryImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (artwork.artistDisplayName != null)
                    Text(
                      'By ${artwork.artistDisplayName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 16),
                  _buildInfoSection(context),
                  const SizedBox(height: 16),
                  if (showARButton)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement AR view
                        },
                        icon: const Icon(Icons.view_in_ar),
                        label: const Text('View in AR'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (artwork.objectURL != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _launchURL(artwork.objectURL!),
                        icon: const Icon(Icons.language),
                        label: const Text('View on MET Website'),
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

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (artwork.objectDate != null)
          _buildInfoRow(context, Icons.date_range, 'Date', artwork.objectDate!),
        if (artwork.medium != null)
          _buildInfoRow(context, Icons.palette, 'Medium', artwork.medium!),
        if (artwork.dimensions != null)
          _buildInfoRow(context, Icons.straighten, 'Dimensions', artwork.dimensions!),
        if (artwork.department != null)
          _buildInfoRow(context, Icons.category, 'Department', artwork.department!),
        if (artwork.culture != null)
          _buildInfoRow(context, Icons.public, 'Culture', artwork.culture!),
        if (artwork.period != null)
          _buildInfoRow(context, Icons.history, 'Period', artwork.period!),
        if (artwork.creditLine != null)
          _buildInfoRow(context, Icons.credit_card, 'Credit Line', artwork.creditLine!),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
} 