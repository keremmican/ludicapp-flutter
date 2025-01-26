import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/game_section.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';
import 'package:ludicapp/features/home/presentation/widgets/main_page_game.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/features/home/presentation/widgets/continue_playing_section.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/core/models/game.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.initializeData();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Showcase Game
          if (_controller.randomGame != null)
            _buildShowcaseGame(context, _controller.randomGame!),

          // New Releases Section
          if (_controller.newReleases.isNotEmpty)
            GameSection(
              title: 'New Releases',
              games: _controller.newReleases.skip(1).map((game) => Game.fromGameSummary(game)).toList(),
              onGameTap: (game) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameDetailPage(game: game),
                  ),
                );
              },
            ),

          const SizedBox(height: 8),

          // Continue Playing Section
          ContinuePlayingSection(
            onAddGamesPressed: () {
              // TODO: Implement add games functionality
            },
          ),

          const SizedBox(height: 8),

          // Top Rated Section
          if (_controller.topRatedGames.isNotEmpty)
            GameSection(
              title: 'Top Rated',
              games: _controller.topRatedGames.map((game) => Game.fromGameSummary(game)).toList(),
              onGameTap: (game) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameDetailPage(game: game),
                  ),
                );
              },
            ),

          const SizedBox(height: 8),

          // Coming Soon Section
          if (_controller.comingSoonGames.isNotEmpty)
            GameSection(
              title: 'Coming Soon',
              games: _controller.comingSoonGames.map((game) => Game.fromGameSummary(game)).toList(),
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

  Widget _buildShowcaseGame(BuildContext context, GameSummary gameSummary) {
    final game = Game.fromGameSummary(gameSummary);
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: MainPageGame(
        game: {
          'image': game.coverUrl ?? '',
          'name': game.name,
          'releaseDate': game.releaseDate ?? 'TBA',
          'rating': game.totalRating?.toString() ?? 'N/A',
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailPage(
                game: game,
              ),
            ),
          );
        },
      ),
    );
  }
}
