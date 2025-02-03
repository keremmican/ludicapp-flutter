import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/features/recommendations/presentation/swipe_card.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/theme/app_theme.dart';


class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final CardSwiperController _swiperController = CardSwiperController();
  final GameRepository _gameRepository = GameRepository();

  // Variable to track swipe direction for background color effect
  double _swipeDirection = 0.0; // Negative for left, positive for right

  // Variable to track the current card index
  int _currentCardIndex = 0;

  // List to store random games
  List<GameSummary> _randomGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRandomGames();
  }

  Future<void> _loadRandomGames() async {
    try {
      final games = await _gameRepository.fetchRandomGames(count: 10);
      
      // Tüm resimleri önceden yükle
      await Future.wait(
        games.map((game) => precacheImage(
          NetworkImage(game.coverUrl ?? ''),
          context,
        )).toList(),
      );

      if (mounted) {
        setState(() {
          _randomGames = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading random games: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ),
        ),
      );
    }

    if (_randomGames.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No games available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadRandomGames,
                child: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Base Background
            Positioned.fill(
              child: Container(color: AppTheme.primaryDark),
            ),
            // Swipeable Cards
            _buildCardStack(),
            // Swipe Overlays
            _buildSwipeOverlays(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    return Center(
      child: _currentCardIndex < _randomGames.length
          ? CardSwiper(
              controller: _swiperController,
              cardsCount: _randomGames.length,
              onSwipe: _onSwipe,
              numberOfCardsDisplayed: 2,
              backCardOffset: const Offset(0, -10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              isDisabled: false,
              isLoop: false,
              maxAngle: 25,
              threshold: 100,
              scale: 0.9,
              duration: const Duration(milliseconds: 200),
              allowedSwipeDirection: AllowedSwipeDirection.only(left: true, right: true),
              cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                if (index >= _randomGames.length) return const SizedBox.shrink();
                
                final game = _randomGames[index];
                final gameDetails = <String, String>{
                  'image': game.coverUrl ?? '',
                  'name': game.name,
                  'genre': game.genres.isNotEmpty ? game.genres.first['name'] as String : 'Unknown',
                  'releaseYear': game.releaseDate?.substring(0, 4) ?? 'TBA',
                  'developer': game.companies.isNotEmpty ? game.companies.first['name'] as String : 'Unknown',
                  'publisher': game.companies.length > 1 ? game.companies[1]['name'] as String : (game.companies.isNotEmpty ? game.companies.first['name'] as String : 'Unknown'),
                  'metacritic': '${(game.totalRating ?? 0).toStringAsFixed(0)}',
                  'matchPoint': '${(game.totalRating ?? 0).toStringAsFixed(0)}',
                  'userReview': game.summary ?? 'No review available.',
                };

                return SwipeCard(
                  game: gameDetails,
                  dominantColor: Colors.black.withOpacity(0.8),
                  horizontalThresholdPercentage: horizontalThresholdPercentage.toDouble(),
                  onTick: () {
                    _swiperController.swipe(CardSwiperDirection.right);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameDetailPage(
                          game: Game.fromGameSummary(game),
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : _buildNoMoreCards(),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (currentIndex == null) return false;
    
    setState(() {
      _swipeDirection = direction == CardSwiperDirection.left ? -1.0 : 1.0;
      _currentCardIndex = currentIndex;

      // If we're running low on cards, load more
      if (_currentCardIndex >= _randomGames.length - 3) {
        _loadMoreGames();
      }
    });

    // Reset swipe direction after animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _swipeDirection = 0.0;
        });
      }
    });

    return true;
  }

  Future<void> _loadMoreGames() async {
    try {
      final newGames = await _gameRepository.fetchRandomGames(count: 5);
      
      // Yeni kartların resimlerini önceden yükle
      await Future.wait(
        newGames.map((game) => precacheImage(
          NetworkImage(game.coverUrl ?? ''),
          context,
        )).toList(),
      );

      if (mounted) {
        setState(() {
          _randomGames.addAll(newGames);
        });
      }
    } catch (e) {
      print('Error loading more games: $e');
    }
  }

  /// Builds the UI when no more cards are left.
  Widget _buildNoMoreCards() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videogame_asset_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No more games to display!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for more recommendations',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeOverlays() {
    const double maxOverlayOpacity = 0.15;
    const double swipeThreshold = 0.1;

    return Stack(
      children: [
        if (_swipeDirection < -swipeThreshold)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 150),
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.red.withOpacity(
                          ((_swipeDirection.abs() - swipeThreshold) / (1.0 - swipeThreshold))
                              .clamp(0.0, 1.0) *
                              maxOverlayOpacity * value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Icon(
                        Icons.close,
                        color: Colors.red.withOpacity(0.8 * value),
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_swipeDirection > swipeThreshold)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 150),
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.greenAccent.withOpacity(
                          ((_swipeDirection - swipeThreshold) / (1.0 - swipeThreshold))
                              .clamp(0.0, 1.0) *
                              maxOverlayOpacity * value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.greenAccent.withOpacity(0.8 * value),
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
