import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RatingModal extends StatefulWidget {
  final String gameName;
  final String coverUrl;
  final String? releaseYear;
  final int? initialRating;
  final Function(int) onRatingSelected;

  const RatingModal({
    Key? key,
    required this.gameName,
    required this.coverUrl,
    this.releaseYear,
    required this.onRatingSelected,
    this.initialRating,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String gameName,
    required String coverUrl,
    String? releaseYear,
    required Function(int) onRatingSelected,
    int? initialRating,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => Container(
        height: MediaQuery.of(context).size.height,
        child: RatingModal(
          gameName: gameName,
          coverUrl: coverUrl,
          releaseYear: releaseYear,
          onRatingSelected: onRatingSelected,
          initialRating: initialRating,
        ),
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
      ),
      child: Stack(
        children: [
          // Main Content
          Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                "I've Seen This",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Game Cover Image
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(widget.coverUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Game Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.gameName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Release Year
              if (widget.releaseYear != null)
                Text(
                  "(${widget.releaseYear})",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 24),
              // Rating Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRatingOption('Awful', const Color(0xFF8E8E93), 0.8),
                    _buildRatingOption('Meh', const Color(0xFFAEA79F), 1.0),
                    _buildRatingOption('Good', const Color(0xFFFFA500), 1.2),
                    _buildRatingOption('Amazing', const Color(0xFFFF6B00), 0.8),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Haven't Seen Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF2C2C2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Haven't Seen",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
          // Close Button
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOption(String label, Color color, double scale) {
    final baseSize = 60.0;
    final size = baseSize * scale;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final rating = _getRatingValue(label);
                widget.onRatingSelected(rating);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(size / 2),
              child: Center(
                child: Icon(
                  _getRatingIcon(label),
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getRatingIcon(String label) {
    switch (label) {
      case 'Amazing':
        return Icons.star_rounded;
      case 'Good':
        return Icons.thumb_up_rounded;
      case 'Meh':
        return Icons.thumbs_up_down_rounded;
      case 'Awful':
        return Icons.thumb_down_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  int _getRatingValue(String label) {
    switch (label) {
      case 'Amazing':
        return 4;
      case 'Good':
        return 3;
      case 'Meh':
        return 2;
      case 'Awful':
        return 1;
      default:
        return 0;
    }
  }
} 