import 'package:flutter/material.dart';

class MainPageGame extends StatelessWidget {
  final Map<String, String> game;
  final VoidCallback onTap;

  const MainPageGame({
    Key? key,
    required this.game,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Stack(
            children: [
              // Game Image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
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

              // Bottom section with game details
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        game['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${game['genre']} • ${game['releaseYear']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
