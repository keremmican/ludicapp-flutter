import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/game_section.dart';
import 'package:ludicapp/features/home/presentation/widgets/main_page_game.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/repository/game_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GameRepository _gameRepository = GameRepository();
  List<GameSummary> _newReleases = [];
  List<GameSummary> _topRatedGames = [];
  GameSummary? _randomGame;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final newReleasesResponse = await _gameRepository.fetchNewReleases();
      final topRatedResponse = await _gameRepository.fetchTopRatedGames();

      setState(() {
        _newReleases = newReleasesResponse.content;
        _topRatedGames = topRatedResponse.content;
        _randomGame = newReleasesResponse.content.isNotEmpty ? newReleasesResponse.content.first : null;
      });
    } catch (error) {
      print("Error loading data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Showcase Game
          if (_randomGame != null)
            _buildShowcaseGame(context, _randomGame!),

          // New Releases Section
          if (_newReleases.isNotEmpty)
            GameSection(
              title: 'New Releases',
              games: _newReleases.skip(1).map((game) => {
                'image': game.coverUrl ?? '',
                'id': game.id.toString(),
              }).toList().cast<Map<String, String>>(),
              onGameTap: (game) {
                final selectedGame = _newReleases.firstWhere(
                  (g) => g.coverUrl == game['image'],
                  orElse: () => GameSummary(
                    id: 0,
                    coverUrl: '',
                    name: 'Unknown',
                    rating: 0,
                    releaseDate: '',
                  ),
                );
                if (selectedGame != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameDetailPage(id: selectedGame.id),
                    ),
                  );
                }
              },
            ),

          // Top Rated Section
          if (_topRatedGames.isNotEmpty)
            GameSection(
              title: 'Top Rated',
              games: _topRatedGames.map((game) => {
                'image': game.coverUrl ?? '',
                'id': game.id.toString(),
              }).toList().cast<Map<String, String>>(),
              onGameTap: (game) {
                final selectedGame = _topRatedGames.firstWhere(
                  (g) => g.coverUrl == game['image'],
                  orElse: () => GameSummary(
                    id: 0,
                    coverUrl: '',
                    name: 'Unknown',
                    rating: 0,
                    releaseDate: '',
                  ),
                );
                if (selectedGame != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameDetailPage(id: selectedGame.id),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShowcaseGame(BuildContext context, GameSummary game) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: MainPageGame(
        game: {
          'image': game.coverUrl ?? '',
          'name': game.name,
          'releaseYear': game.releaseDate ?? 'TBA',
          'rating': game.rating?.toString() ?? 'N/A',
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailPage(
                id: game.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
