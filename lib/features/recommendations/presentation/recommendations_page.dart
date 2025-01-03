import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/features/recommendations/presentation/swipe_card.dart';
import 'package:scrumlab_flutter_tindercard/scrumlab_flutter_tindercard.dart';
import 'package:palette_generator/palette_generator.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  // Enhanced mock data to include genre, release year, developer, publisher, metacritic, imdb
  static const List<Map<String, String>> mockGames = [
    {
      'image': 'lib/assets/images/mock_games/game1.jpg',
      'name': 'Grand Theft Auto VI',
      'genre': 'Action-Adventure',
      'releaseYear': '2024',
      'developer': 'Rockstar Games',
      'publisher': 'Rockstar Games',
      'metacritic': '97',
      'imdb': '9.0',
    },
    {
      'image': 'lib/assets/images/mock_games/game2.jpg',
      'name': 'Cyberpunk 2077: Phantom Liberty',
      'genre': 'RPG',
      'releaseYear': '2023',
      'developer': 'CD Projekt Red',
      'publisher': 'CD Projekt',
      'metacritic': '86',
      'imdb': '8.5',
    },
    {
      'image': 'lib/assets/images/mock_games/game3.jpg',
      'name': 'The Witcher 4',
      'genre': 'RPG',
      'releaseYear': '2025',
      'developer': 'CD Projekt Red',
      'publisher': 'CD Projekt',
      'metacritic': '90',
      'imdb': '8.8',
    },
    {
      'image': 'lib/assets/images/mock_games/game4.jpg',
      'name': 'Halo Infinite',
      'genre': 'First-Person Shooter',
      'releaseYear': '2021',
      'developer': '343 Industries',
      'publisher': 'Microsoft Studios',
      'metacritic': '91',
      'imdb': '8.7',
    },
    {
      'image': 'lib/assets/images/mock_games/game5.jpg',
      'name': 'Minecraft Legends',
      'genre': 'Sandbox',
      'releaseYear': '2022',
      'developer': 'Mojang Studios',
      'publisher': 'Xbox Game Studios',
      'metacritic': '84',
      'imdb': '8.3',
    },
    {
      'image': 'lib/assets/images/mock_games/game6.jpg',
      'name': 'FIFA 24',
      'genre': 'Sports',
      'releaseYear': '2023',
      'developer': 'EA Sports',
      'publisher': 'Electronic Arts',
      'metacritic': '80',
      'imdb': '7.8',
    },
  ];

  final CardController _cardController = CardController(); // Controller for the swipe cards

  // Variable to track swipe direction for background color effect
  double _swipeDirection = 0.0; // Negative for left, positive for right

  // Variable to track the current card index
  int _currentCardIndex = 0;

  // List of mock user reviews
  static const List<String> _mockReviews = [
    "Absolutely loved the gameplay mechanics!",
    "A bit too long but worth every minute.",
    "Graphics are stunning, but the story lacks depth.",
    "Highly recommended for action game enthusiasts.",
    "Could use more diverse missions.",
    "An excellent addition to the series!",
  ];

  final Random _random = Random(); // Random generator for selecting reviews

  // Precomputed game data with reviews and match points
  late final List<Map<String, String>> _gamesWithDetails;

  List<Color?> _dominantColors = []; // List to store dominant colors, nullable

  @override
  void initState() {
    super.initState();
    _gamesWithDetails = mockGames.map((game) {
      return {
        ...game,
        'userReview': _mockReviews[_random.nextInt(_mockReviews.length)],
        'matchPoint': _random.nextInt(101).toString(), // 0 to 100 as String
      };
    }).toList();

    // Initialize the dominantColors list with nulls
    _dominantColors = List<Color?>.filled(_gamesWithDetails.length, null);

    // Extract the dominant color for the first two cards immediately
    _extractDominantColor(_currentCardIndex);
    if (_gamesWithDetails.length > 1) {
      _extractDominantColor(_currentCardIndex + 1);
    }
  }

  /// Extracts the dominant color for a specific card index
  Future<void> _extractDominantColor(int index) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        AssetImage(_gamesWithDetails[index]['image']!),
        size: Size(200, 100), // Optional: Specify size to speed up
        maximumColorCount: 20, // Reduce the number of colors to analyze
      );
      final color = paletteGenerator.dominantColor?.color ?? Colors.grey.withOpacity(0.5);

      setState(() {
        _dominantColors[index] = color;
      });
    } catch (e) {
      // Handle any errors during color extraction
      print('Error extracting color for card $index: $e');
      setState(() {
        _dominantColors[index] = Colors.grey.withOpacity(0.5);
      });
    }
  }

  /// Preloads dominant colors for the next [preloadCount] cards
  void _preloadNextColors(int currentIndex, {int preloadCount = 2}) {
    for (int i = 1; i <= preloadCount; i++) {
      int nextIndex = currentIndex + i;
      if (nextIndex < _gamesWithDetails.length && _dominantColors[nextIndex] == null) {
        _extractDominantColor(nextIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the maximum overlay opacity
    const double maxOverlayOpacity = 0.15; // Lighter opacity

    // Define the swipe threshold
    const double swipeThreshold = 0.1; // Start showing overlay after 10% swipe

    // Determine if initial loading is still ongoing (only first two cards loaded)
    bool initialLoading = _dominantColors[0] == null || (_gamesWithDetails.length > 1 && _dominantColors[1] == null);

    if (initialLoading) {
      return Scaffold(
        backgroundColor: Colors.black, // Set the page background to black
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // Set the page background to black
      body: SafeArea(
        child: Stack(
          children: [
            // Base Background
            Positioned.fill(
              child: Container(color: Colors.black),
            ),
            // Red Overlay for Swiping Left
            if (_swipeDirection < -swipeThreshold)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.red.withOpacity(
                              ((_swipeDirection.abs() - swipeThreshold) / (1.0 - swipeThreshold))
                                  .clamp(0.0, 1.0) *
                                  maxOverlayOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Green Overlay for Swiping Right
            if (_swipeDirection > swipeThreshold)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.green.withOpacity(
                              ((_swipeDirection - swipeThreshold) / (1.0 - swipeThreshold))
                                  .clamp(0.0, 1.0) *
                                  maxOverlayOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Swipeable Cards
            Center(
  child: _currentCardIndex < _gamesWithDetails.length
      ? TinderSwapCard(
          orientation: AmassOrientation.bottom,
          totalNum: _gamesWithDetails.length - _currentCardIndex,
          stackNum: 3,
          swipeEdge: 4.0,
          maxWidth: MediaQuery.of(context).size.width * 0.92, // Slightly wider
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minWidth: MediaQuery.of(context).size.width * 0.88, // Increased width
          minHeight: MediaQuery.of(context).size.height * 0.8,
          cardBuilder: (context, index) {
            final gameDetails = _gamesWithDetails[_currentCardIndex + index];
            final color = _dominantColors[_currentCardIndex + index] ?? Colors.grey.withOpacity(0.5);
            return SwipeCard(
              game: gameDetails,
              dominantColor: color,
              onTick: () {
                print('Tick button pressed for ${gameDetails['name']}');
                _cardController.triggerRight();
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameDetailPage(id: 0,),
                  ),
                );
              },
            );
          },
          cardController: _cardController,
          swipeUpdateCallback:
              (DragUpdateDetails details, Alignment align) {
            setState(() {
              _swipeDirection = align.x;
            });
          },
          swipeCompleteCallback:
              (CardSwipeOrientation orientation, int index) {
            setState(() {
              _swipeDirection = 0.0;
              _currentCardIndex++;
            });

            _preloadNextColors(_currentCardIndex - 1);

            if (orientation == CardSwipeOrientation.right) {
              print('Swiped Right on card ${_currentCardIndex - 1}');
            } else if (orientation == CardSwipeOrientation.left) {
              print('Swiped Left on card ${_currentCardIndex - 1}');
            }
          },
        )
      : _buildNoMoreCards(),
),

          ],
        ),
      ),
    );
  }

  /// Builds the UI when no more cards are left.
  Widget _buildNoMoreCards() {
    return Center(
      child: Text(
        'No more games to display!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
