import 'package:flutter/material.dart';

class LevelComponent extends StatelessWidget {
  final int level;
  final double progress; // Value between 0.0 and 1.0

  const LevelComponent({
    Key? key,
    required this.level,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Progress Circle
            SizedBox(
              width: 20, // Daha da küçültülmüş boyut
              height: 20, // Daha da küçültülmüş boyut
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5, // Daha ince stroke
                backgroundColor: Colors.grey.shade700,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFBFE429)), // Yeşil renk
              ),
            ),
            // Inner Icon
            Icon(
              Icons.star, // İkon
              color: Colors.yellowAccent,
              size: 16, // Daha da küçültülmüş ikon boyutu
            ),
          ],
        ),
        const SizedBox(height: 6), // Daha küçük boşluk
        Text(
          'Level $level',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12, // Daha küçük font boyutu
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
