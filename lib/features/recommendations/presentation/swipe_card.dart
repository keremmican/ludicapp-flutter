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
    // Increased frosted area height
    const double frostedHeight = 160.0; // Artırıldı: 150'dan 160'a

    return GestureDetector(
      onTap: onTap, // Handle tap on the entire card
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 15), // İsteğe bağlı: 8 ve 15 olarak bırakıldı
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
                        // Left column with match point, title, genre-year, and review
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Match Point
                              Text(
                                '${game['matchPoint']}% Match',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 15, // Orijinal: 14'tan 15'e yükseltildi
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Game Title
                              Text(
                                game['name']!,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontSize: 17, // Orijinal: 16'dan 17'ye yükseltildi
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Genre and Release Year
                              Text(
                                '${game['genre']} • ${game['releaseYear']}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white70,
                                  fontSize: 13, // Orijinal: 12'den 13'e yükseltildi
                                ),
                              ),
                              const SizedBox(height: 1), // Azaltılmadı

                              // Horizontal Grey Line
                              Divider(
                                color: Colors.grey[700],
                                thickness: 1,
                                height: 8,
                              ),
                              const SizedBox(height: 1), // Azaltılmadı

                              // User Review
                              Text(
                                '"${game['userReview']}"',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15, // Orijinal: 14'ten 15'e yükseltildi
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Transparent Tick Icon in Grey Circle
                        GestureDetector(
                          onTap: onTick, // Handle tick action
                          child: Container(
                            width: 34, // 32'den 34'e artırıldı
                            height: 34, // 32'den 34'e artırıldı
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey, // Grey border color
                                width: 2, // Border thickness
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.grey, // Grey check icon
                              size: 20, // Orijinal: 18'den 20'ye artırıldı
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
