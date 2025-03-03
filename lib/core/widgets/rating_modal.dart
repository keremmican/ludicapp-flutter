import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RatingModal extends StatefulWidget {
  final String gameName;
  final String coverUrl;
  final int? initialRating;
  final Function(int) onRatingSelected;

  const RatingModal({
    Key? key,
    required this.gameName,
    required this.coverUrl,
    required this.onRatingSelected,
    this.initialRating,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String gameName,
    required String coverUrl,
    required Function(int) onRatingSelected,
    int? initialRating,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.7 > 500 ? 500.0 : screenHeight * 0.7;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => Container(
        constraints: BoxConstraints(
          maxHeight: modalHeight,
        ),
        child: RatingModal(
          gameName: gameName,
          coverUrl: coverUrl,
          onRatingSelected: onRatingSelected,
          initialRating: initialRating,
        ),
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: FadeTransition(
              opacity: _animationController,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Text(
                        "Rate This Game",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Game Cover - Centered
                    Center(
                      child: Hero(
                        tag: "game_cover_${widget.gameName}",
                        child: Container(
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(widget.coverUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Game Title - Below Cover
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.gameName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Rating Options
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRatingOption('Awful', const Color(0xFF8E8E93), 0.8, 1),
                          _buildRatingOption('Meh', const Color(0xFFAEA79F), 1.0, 2),
                          _buildRatingOption('Good', const Color(0xFFFFA500), 1.2, 3),
                          _buildRatingOption('Amazing', const Color(0xFFFF6B00), 0.8, 4),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Haven't Played Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.white24),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          "Haven't Played",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Close Button
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOption(String label, Color color, double scale, int ratingValue) {
    final baseSize = 60.0;
    final size = baseSize * scale;
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onRatingSelected(ratingValue);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(size / 2),
              child: Container(
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
} 