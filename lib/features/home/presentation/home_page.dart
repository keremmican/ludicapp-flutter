import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/game_section.dart';
import 'package:ludicapp/core/widgets/large_game_section.dart';
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
  final _scrollController = ScrollController();
  bool _hasTriggeredLoad = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasTriggeredLoad && 
        _scrollController.position.pixels > _scrollController.position.maxScrollExtent * 0.2 &&
        _controller.hasMoreSections) {
      _hasTriggeredLoad = true;
      _loadMoreSections();
    }
  }

  Future<void> _loadData() async {
    await _controller.initializeData();
    if (mounted) setState(() {});
  }

  Future<void> _loadMoreSections() async {
    await _controller.loadMoreSections();
    if (mounted) {
      setState(() {
        // Reset the trigger if there are more sections to load
        if (_controller.hasMoreSections) {
          _hasTriggeredLoad = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Showcase Game
          if (_controller.popularGameByVisits != null)
            _buildShowcaseGame(context, _controller.popularGameByVisits!),

          // New Releases Section
          if (_controller.newReleases.isNotEmpty)
            GameSection(
              title: 'New Releases',
              games: _controller.newReleases.map((game) => Game.fromGameSummary(game)).toList(),
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

          // Popularity Type Sections
          ..._controller.popularityTypeGames.entries.map((entry) {
            final popularityType = entry.key;
            final games = entry.value;
            if (games.isEmpty) return const SizedBox.shrink();

            final index = _controller.popularityTypeGames.keys.toList().indexOf(popularityType);
            final isLargeSection = index % 2 == 0; // Alternate between normal and large sections

            return Column(
              children: [
                const SizedBox(height: 8),
                if (isLargeSection)
                  LargeGameSection(
                    title: _controller.getPopularityTypeTitle(popularityType),
                    games: games.map((game) => Game.fromGameSummary(game)).toList(),
                    onGameTap: (game) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameDetailPage(game: game),
                        ),
                      );
                    },
                  )
                else
                  GameSection(
                    title: _controller.getPopularityTypeTitle(popularityType),
                    games: games.map((game) => Game.fromGameSummary(game)).toList(),
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
            );
          }).toList(),

          if (_controller.isLoadingMoreSections)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
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
        game: gameSummary,
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
