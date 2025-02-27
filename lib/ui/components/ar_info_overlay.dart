import 'package:flutter/material.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/utils/constants.dart';

class ARInfoOverlay extends StatelessWidget {
  final Artwork artwork;
  final double confidence;

  const ARInfoOverlay({
    Key? key,
    required this.artwork,
    required this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(UIConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with image thumbnail
          Row(
            children: [
              if (artwork.primaryImageUrl != null)
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(UIConstants.borderRadius / 2),
                    image: DecorationImage(
                      image: NetworkImage(artwork.primaryImageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(UIConstants.borderRadius / 2),
                  ),
                  child: const Icon(Icons.image_not_supported, color: Colors.white, size: 30),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (artwork.artistName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          artwork.artistName!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildConfidenceIndicator(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Info section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (artwork.department != null)
                  _buildInfoRow(Icons.category, artwork.department!),
                if (artwork.year != null)
                  _buildInfoRow(Icons.date_range, artwork.year.toString()),
                if (artwork.culture != null)
                  _buildInfoRow(Icons.public, artwork.culture!),
                
                const SizedBox(height: 8),
                
                // Action button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    onPressed: () {
                      // Navigator is handled by the parent widget
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Details'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final double percentage = confidence * 100;
    Color indicatorColor;
    
    if (percentage >= 90) {
      indicatorColor = Colors.green;
    } else if (percentage >= 75) {
      indicatorColor = Colors.yellowAccent;
    } else {
      indicatorColor = Colors.orange;
    }
    
    return Row(
      children: [
        Text(
          'Match: ${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
} 