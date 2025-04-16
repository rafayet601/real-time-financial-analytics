import 'package:flutter/material.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/utils/constants.dart';
import 'package:met_museum_explorer/ui/screens/ar_view_screen.dart';

class ARInfoOverlay extends StatelessWidget {
  final Artwork artwork;
  final double confidence;
  final bool showARButton;

  const ARInfoOverlay({
    Key? key,
    required this.artwork,
    required this.confidence,
    this.showARButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  artwork.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showARButton)
                IconButton(
                  icon: const Icon(Icons.view_in_ar, color: Colors.white),
                  tooltip: 'View in AR',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ARViewScreen(artwork: artwork),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (artwork.artistDisplayName != null) ...[
            const SizedBox(height: 8),
            Text(
              'By ${artwork.artistDisplayName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (artwork.objectDate != null) ...[
            const SizedBox(height: 8),
            Text(
              artwork.objectDate!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}% match',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 