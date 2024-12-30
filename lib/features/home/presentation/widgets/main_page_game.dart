import 'package:flutter/material.dart';

class MainPageGame extends StatelessWidget {
  final Map<String, String> game; // Pass game data
  final VoidCallback onTap; // Callback for click action

  const MainPageGame({
    Key? key,
    required this.game,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle tap on the card
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Same roundness as SwipeCard
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6, // Adjusted height to 60%
          decoration: BoxDecoration(
  image: DecorationImage(
    image: game['image']!.startsWith('http') // Eğer URL bir ağ bağlantısıysa
        ? NetworkImage(game['image']!) as ImageProvider
        : AssetImage(game['image']!), // Eğer URL değilse yerel dosya
    fit: BoxFit.cover,
  ),
  borderRadius: BorderRadius.circular(20),
),
          child: Stack(
            children: [
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
                      // Game Name
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
                      // Genre and Release Year
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
