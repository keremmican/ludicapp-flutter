import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter

/// A widget that represents a single category card in the game library.
class LibraryCategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const LibraryCategoryCard({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle tap on the card
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8), // Rounded corners
        child: Stack(
          children: [
            // Background Image with Blur Effect
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Increased blur intensity
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Semi-transparent Overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3), // Reduced opacity for lighter overlay
              ),
            ),

            // Centered Bold Text
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced padding
                child: Text(
                  title,
                  textAlign: TextAlign.center, // Center-align text
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Increased font size for better readability
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                  maxLines: 2, // Allow two lines for longer titles
                  overflow: TextOverflow.ellipsis, // Ellipsis for overflow
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
