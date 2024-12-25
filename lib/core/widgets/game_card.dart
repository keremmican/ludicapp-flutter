import 'package:flutter/material.dart';

/// A widget that represents a single game card in horizontal lists.
class GameCard extends StatelessWidget {
  final Map<String, String> game; // Pass game data
  final VoidCallback onTap; // Callback for tap action

  const GameCard({
    Key? key,
    required this.game,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle tap on the card
      child: Container(
        width: 120, // Adjust width as needed
        margin: const EdgeInsets.only(right: 10.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(game['image']!),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3), // Adjust opacity as needed
              BlendMode.darken,
            ),
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              game['name']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Adjust font size as needed
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
