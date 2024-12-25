import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/game_section.dart';
import 'package:ludicapp/features/home/presentation/widgets/main_page_game.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';

class HomePage extends StatelessWidget {
  static const List<String> mockImages = [
    'lib/assets/images/mock_games/game1.jpg',
    'lib/assets/images/mock_games/game2.jpg',
    'lib/assets/images/mock_games/game3.jpg',
    'lib/assets/images/mock_games/game4.jpg',
    'lib/assets/images/mock_games/game5.jpg',
    'lib/assets/images/mock_games/game6.jpg',
  ];

  // Mock data for showcase game
  final Map<String, String> showcaseGame = {
    'image': 'lib/assets/images/mock_games/game1.jpg',
    'name': 'Cyberpunk 2077',
    'genre': 'RPG',
    'releaseYear': '2023',
    'developer': 'CD Projekt Red',
    'publisher': 'CD Projekt',
    'metacritic': '86',
    'imdb': '8.5',
  };

  // Mock data for horizontal list games
  final List<Map<String, String>> horizontalGames = List.generate(10, (index) {
    return {
      'image': mockImages[index % mockImages.length],
      'name': 'Game ${index + 1}',
      'genre': 'Genre ${index + 1}',
      'releaseYear': '202${index % 10}',
      'developer': 'Developer ${index + 1}',
      'publisher': 'Publisher ${index + 1}',
      'metacritic': '${80 + index % 20}',
      'imdb': '${7 + (index % 4) * 0.5}',
    };
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Showcase Game
          _buildShowcaseGame(context),

          // Upcoming Games Section
          GameSection(
            title: 'Upcoming Games',
            games: horizontalGames,
            onGameTap: (game) {
              // Navigate to GameDetailPage when a game is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailPage(game: game),
                ),
              );
            },
          ),

          // Top Rated Games Section
          GameSection(
            title: 'Top Rated Games',
            games: horizontalGames,
            onGameTap: (game) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailPage(game: game),
                ),
              );
            },
          ),

          // Last Seen Section
          GameSection(
            title: 'Last Seen',
            games: horizontalGames,
            onGameTap: (game) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameDetailPage(game: game),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseGame(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: MainPageGame(
        game: showcaseGame,
        onTap: () {
          // Navigate to GameDetailPage with showcase game data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailPage(game: showcaseGame),
            ),
          );
        },
      ),
    );
  }
}
