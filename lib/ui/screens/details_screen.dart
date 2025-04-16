import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/utils/constants.dart';
import 'package:met_museum_explorer/ui/screens/ar_view_screen.dart';

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
              title: Text(
                 artwork.title,
                 style: const TextStyle(fontSize: 16), 
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
              background: artwork.primaryImage != null && artwork.primaryImage!.isNotEmpty
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (artwork.artistDisplayName != null && artwork.artistDisplayName!.isNotEmpty)
                    Text(
                      'By ${artwork.artistDisplayName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 16),
                  _buildInfoSection(context),
                  const SizedBox(height: 24),
                  if (showARButton && AppConstants.enableAR)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ARViewScreen(artwork: artwork),
                            ),
                          );
                        },
                        icon: const Icon(Icons.view_in_ar),
                        label: const Text('View in AR'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (artwork.objectURL != null && artwork.objectURL!.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _launchURL(artwork.objectURL!),
                        icon: const Icon(Icons.language),
                        label: const Text('View on MET Website'),
                      ),
                    ),
                    const SizedBox(height: 20),
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
        if (artwork.objectDate != null && artwork.objectDate!.isNotEmpty)
          _buildInfoRow(context, Icons.date_range, 'Date', artwork.objectDate!),
        if (artwork.medium != null && artwork.medium!.isNotEmpty)
          _buildInfoRow(context, Icons.palette, 'Medium', artwork.medium!),
        if (artwork.dimensions != null && artwork.dimensions!.isNotEmpty)
          _buildInfoRow(context, Icons.straighten, 'Dimensions', artwork.dimensions!),
        if (artwork.department != null && artwork.department!.isNotEmpty)
          _buildInfoRow(context, Icons.category, 'Department', artwork.department!),
        if (artwork.culture != null && artwork.culture!.isNotEmpty)
          _buildInfoRow(context, Icons.public, 'Culture', artwork.culture!),
        if (artwork.period != null && artwork.period!.isNotEmpty)
          _buildInfoRow(context, Icons.history, 'Period', artwork.period!),
        if (artwork.creditLine != null && artwork.creditLine!.isNotEmpty)
          _buildInfoRow(context, Icons.credit_card, 'Credit Line', artwork.creditLine!),
         if (artwork.accessionNumber != null && artwork.accessionNumber!.isNotEmpty)
          _buildInfoRow(context, Icons.confirmation_number, 'Accession No.', artwork.accessionNumber!),
      ].where((widget) => widget != null).toList().cast<Widget>(),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                 const SizedBox(height: 2),
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
    try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
        print('Could not launch $url');
        }
    } catch (e) {
        print('Error launching URL: $e');
    }
  }
} 