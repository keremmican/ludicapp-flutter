import 'dart:ui';
import 'package:flutter/material.dart';

/// A widget that represents a single swipeable recommendation card.
class SwipeCard extends StatelessWidget {
  final Map<String, String> game;
  final VoidCallback onTick;
  final VoidCallback onTap;
  final Color dominantColor;

  const SwipeCard({
    Key? key,
    required this.game,
    required this.onTick,
    required this.onTap,
    required this.dominantColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double frostedHeight = 160.0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Game Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(game['image']!),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            // Bottom section with frosted glass effect
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: frostedHeight,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    decoration: BoxDecoration(
                      color: dominantColor.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Game Title
                              Flexible(
                                child: Text(
                                  game['name']!,
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Match Point
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${game['matchPoint']}% Match',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Genre and Release Year
                              Text(
                                '${game['genre']} • ${game['releaseYear']}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 1),
                              // Horizontal Grey Line
                              Divider(
                                color: Colors.grey[700],
                                thickness: 1,
                                height: 8,
                              ),
                              const SizedBox(height: 1),
                              // User Review
                              Text(
                                game['userReview']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tick Icon
                        GestureDetector(
                          onTap: onTick,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
