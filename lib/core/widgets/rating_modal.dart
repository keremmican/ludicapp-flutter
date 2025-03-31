import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ludicapp/services/repository/rating_repository.dart';

class RatingModal extends StatefulWidget {
  final String gameName;
  final String coverUrl;
  final int gameId;
  final int? initialRating;
  final Function(int) onRatingSelected;

  const RatingModal({
    Key? key,
    required this.gameName,
    required this.coverUrl,
    required this.gameId,
    required this.onRatingSelected,
    this.initialRating,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String gameName,
    required String coverUrl,
    required int gameId,
    required Function(int) onRatingSelected,
    int? initialRating,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.7 > 500 ? 500.0 : screenHeight * 0.7;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: modalHeight,
            ),
            child: RatingModal(
              gameName: gameName,
              coverUrl: coverUrl,
              gameId: gameId,
              onRatingSelected: onRatingSelected,
              initialRating: initialRating,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final RatingRepository _ratingRepository = RatingRepository();
  bool _isLoading = false;
  
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

  Future<void> _handleRating(int rating) async {
    if (rating == widget.initialRating) {
      Navigator.pop(context);
      return;
    }

    try {
      await _ratingRepository.rateGame(widget.gameId, rating);
      if (mounted) {
        widget.onRatingSelected(rating);
        Navigator.pop(context);
      }
    } catch (e) {
      print('Rating error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update rating. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteRating() async {
    try {
      final success = await _ratingRepository.deleteRating(widget.gameId);
      if (success) {
        if (mounted) {
          widget.onRatingSelected(0);
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to delete rating');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove rating. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Stack(
      children: [
        Container(
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
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _animationController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.initialRating != null && widget.initialRating! > 0 ? "Change Your Rating" : "Rate This Game",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                            onPressed: _isLoading ? null : _handleDeleteRating,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.white24),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                    ),
                                  )
                                : const Text(
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
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingOption(String label, Color color, double scale, int ratingValue) {
    final baseSize = 60.0;
    final size = baseSize * scale;
    final isSelected = widget.initialRating == ratingValue;
    final isDimmed = widget.initialRating != null && !isSelected;
    
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
              onTap: _isLoading ? null : () => _handleRating(ratingValue),
              borderRadius: BorderRadius.circular(size / 2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isDimmed ? color.withOpacity(0.3) : color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isDimmed)
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
                    color: isDimmed ? Colors.white.withOpacity(0.3) : Colors.white,
                    size: size * 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDimmed ? Colors.white30 : Colors.white70,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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