import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/core/utils/date_formatter.dart';

/// A widget that represents a single swipeable recommendation card.
class SwipeCard extends StatelessWidget {
  final Map<String, String> game;
  final VoidCallback onTick;
  final VoidCallback onTap;
  final Color dominantColor;
  final double horizontalThresholdPercentage;

  const SwipeCard({
    Key? key,
    required this.game,
    required this.onTick,
    required this.onTap,
    required this.dominantColor,
    this.horizontalThresholdPercentage = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate rotation angle based on swipe direction
    final rotationAngle = (horizontalThresholdPercentage / 100) * 0.3;
    
    return Transform.translate(
      offset: Offset(horizontalThresholdPercentage, 0),
      child: Transform.rotate(
        angle: rotationAngle,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Game Image
                  SizedBox.expand(
                    child: Image.network(
                      game['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                  // Dark Overlay for better readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.5, 0.75, 0.9],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        // Game Title and Match Point Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                game['name']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.greenAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${game['matchPoint']}%',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Game Info Row
                        Row(
                          children: [
                            _buildInfoChip(Icons.sports_esports, game['genre']!),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.calendar_today, DateFormatter.formatYear(game['releaseYear'])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Review
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.format_quote,
                                color: Colors.white.withOpacity(0.4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  game['userReview']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.4,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
