import 'package:flutter/material.dart';

class GameSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> games;
  final Function(Map<String, String>) onGameTap;

  const GameSection({
    Key? key,
    required this.title,
    required this.games,
    required this.onGameTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontally Scrolling Game Cards
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return GestureDetector(
                  onTap: () => onGameTap(game),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: game['image']!.startsWith('http')
                          ? Image.network(
                              game['image']!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.error, color: Colors.white),
                                );
                              },
                            )
                          : Image.asset(
                              game['image']!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
