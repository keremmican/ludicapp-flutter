import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/features/recommendations/presentation/swipe_card.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/features/recommendations/application/recommendations_notifier.dart';
import 'package:ludicapp/theme/app_theme.dart';

class RecommendationPage extends ConsumerStatefulWidget {
  const RecommendationPage({super.key});

  @override
  ConsumerState<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends ConsumerState<RecommendationPage> with SingleTickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    // Precache images when the page is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages();
    });
  }

  Future<void> _precacheImages() async {
    final games = ref.read(recommendationsNotifierProvider).value?.games ?? [];
    await Future.wait(
      games.map((game) => precacheImage(
        NetworkImage(game.coverUrl ?? ''),
        context,
      )).toList(),
    );
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(recommendationsNotifierProvider);

    return recommendationsAsync.when(
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error),
      data: (state) {
        if (state.noMoreGamesInitially) {
          return _buildNoGamesScreen();
        }
        return _buildMainScreen(state);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading recommendations...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object error) {
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
              'Error loading recommendations',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(recommendationsNotifierProvider.notifier).refreshGames(),
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

  Widget _buildNoGamesScreen() {
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
              onPressed: () => ref.read(recommendationsNotifierProvider.notifier).refreshGames(),
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

  Widget _buildMainScreen(RecommendationsState state) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: AppTheme.primaryDark),
            ),
            _buildCardStack(state),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack(RecommendationsState state) {
    final remainingCards = state.games.length - state.currentCardIndex;
    const int loadMoreThreshold = 3; 
    if (remainingCards <= 0) return _buildNoMoreCards(state);

    // Update the key to depend on both list length and current index
    final swiperKey = ValueKey('${state.games.length}-${state.currentCardIndex}');

    return Center(
      child: CardSwiper(
        key: swiperKey,
        controller: _swiperController,
        cardsCount: remainingCards, 
        onSwipe: (previousRelativeIndex, currentRelativeIndexNullable, direction) {
          final actualSwipedIndex = state.currentCardIndex + previousRelativeIndex;
          
          // 1. Update the index first
          ref.read(recommendationsNotifierProvider.notifier).swipe(
                actualSwipedIndex,
                direction,
              );

          // 2. Check and load more games *after* the current frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Read the latest state after swipe
            final latestState = ref.read(recommendationsNotifierProvider).value;
            if (latestState != null) {
              final latestRemaining = latestState.games.length - latestState.currentCardIndex;
              if (!latestState.isLoadingMore && 
                  !latestState.allGamesLoaded && 
                  latestRemaining <= loadMoreThreshold) {
                ref.read(recommendationsNotifierProvider.notifier).loadMoreGames();
              }
            }
          });

          return true;
        },
        numberOfCardsDisplayed: 3,
        backCardOffset: const Offset(0, -15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        isDisabled: false,
        isLoop: false,
        maxAngle: 30,
        threshold: 50,
        scale: 0.95,
        duration: const Duration(milliseconds: 400),
        allowedSwipeDirection: AllowedSwipeDirection.only(left: true, right: true),
        cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
          final actualIndex = state.currentCardIndex + index;
          
          // Add extra safety check for index bounds
          if (actualIndex < 0 || actualIndex >= state.games.length) {
             print('Warning: CardBuilder trying to access invalid index $actualIndex. currentCardIndex: ${state.currentCardIndex}, index: $index, games.length: ${state.games.length}');
             return const SizedBox.shrink(); // Return an empty box if index is invalid
          }
          
          final game = state.games[actualIndex];
          
          // LOG: Card being built
          print('BUILDING CARD - Relative Index: $index, Actual Index: $actualIndex, Game ID: ${game.id}, Name: ${game.name}');

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
              _navigateToGameDetails(game);
            },
          );
        },
      ),
    );
  }

  void _navigateToGameDetails(GameSummary game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailPage(
          game: Game.fromGameSummary(game),
        ),
      ),
    );
  }

  Widget _buildNoMoreCards(RecommendationsState state) {
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(recommendationsNotifierProvider.notifier).refreshGames(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Refresh Games',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
