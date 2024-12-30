import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/game_section.dart';
import 'package:ludicapp/features/home/presentation/widgets/main_page_game.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/top_games_cover.dart';
import 'package:ludicapp/services/repository/game_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<String> mockImages = [
    'https://images.igdb.com/igdb/image/upload/t_1080p/co7497.jpg'
  ];

  final GameRepository _gameRepository = GameRepository();
  static List<GameSummary> _newReleases = [];
  static List<TopRatedGamesCover> _topRatedGames = [];
  static GameSummary? _randomGame;
  static bool _hasFetchedData = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!_hasFetchedData) {
      _fetchNewReleases();
      _fetchTopRatedGames();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNewReleases() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final newReleases = await _gameRepository.fetchNewReleases();
      setState(() {
        _newReleases = newReleases;
        _randomGame = newReleases.isNotEmpty ? newReleases.first : null;
        _hasFetchedData = true;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching new releases: $error");
    }
  }

  Future<void> _fetchTopRatedGames() async {
    try {
      final topRatedGames = await _gameRepository.fetchTopRatedGames();
      setState(() {
        _topRatedGames = topRatedGames;
        _hasFetchedData = true;
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching top rated games: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Showcase Game (First item in the list or loading indicator)
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_randomGame != null)
            _buildShowcaseGame(context, _randomGame!),

          // New Releases Section
          if (_newReleases.isNotEmpty)
            GameSection(
  title: 'New Releases',
  games: _newReleases.skip(1).map((game) => {
    'image': game.coverUrl,
    'id': game.id.toString(),
  }).toList(),
  onGameTap: (game) {
    final selectedGame = _newReleases.firstWhere(
      (g) => g.coverUrl == game['image'],
      orElse: () => GameSummary(
        id: 0,
        coverUrl: '',
        name: 'Unknown',
        genre: '',
        releaseYear: 0,
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
    'image': game.coverUrl,
    'id': game.id.toString(),
  }).toList(),
  onGameTap: (game) {
    final selectedGame = _topRatedGames.firstWhere(
      (g) => g.coverUrl == game['image'],
      orElse: () => TopRatedGamesCover(id: 0, coverUrl: ''),
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


          // Last Seen Section (Mock Data)
          /*GameSection(
            title: 'Last Seen',
            games: mockImages.map((image) => {
              'image': image,
              'name': 'Last Seen Game',
              'genre': 'Genre',
              'releaseYear': '2021',
              'developer': 'Last Dev',
              'publisher': 'Last Publisher',
              'metacritic': '85',
              'imdb': '8.5',
            }).toList(),
            onGameTap: (game) {
    final selectedGame = _topRatedGames.firstWhere(
      (g) => g.coverUrl == game['image'],
      orElse: () => null,
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
          ),*/
        ],
      ),
    );
  }

  Widget _buildShowcaseGame(BuildContext context, GameSummary game) {
  return Padding(
    padding: const EdgeInsets.all(15.0),
    child: MainPageGame(
      game: {
        'image': game.coverUrl,
        'name': game.name,
        'genre': game.genre,
        'releaseYear': game.releaseYear.toString(),
        'developer': 'Unknown',
        'publisher': 'Unknown',
        'metacritic': 'N/A',
        'imdb': 'N/A',
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameDetailPage(
              id: game.id, // 'id' parametresi eklendi
            ),
          ),
        );
      },
    ),
  );
}

}
