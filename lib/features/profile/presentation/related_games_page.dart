import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/top_games_cover.dart';

class RelatedGamesPage extends StatefulWidget {
  final String categoryTitle;

  const RelatedGamesPage({Key? key, required this.categoryTitle})
      : super(key: key);

  @override
  State<RelatedGamesPage> createState() => _RelatedGamesPageState();
}

class _RelatedGamesPageState extends State<RelatedGamesPage> {
  final GameRepository _gameRepository = GameRepository();
  List<dynamic> games = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      if (widget.categoryTitle == 'New Releases') {
        final newReleases = await _gameRepository.fetchNewReleases();
        setState(() {
          games = newReleases;
        });
      } else if (widget.categoryTitle == 'Top Rated') {
        final topRated = await _gameRepository.fetchTopRatedGames();
        setState(() {
          games = topRated;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  _buildFilterButton('Recently Added', isSelected: true),
                  _buildFilterButton('Available to Play'),
                  _buildFilterButton('Hide Rated'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (error != null)
            Expanded(
              child: Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (games.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No games available in this category.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          else
            // Game Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.53,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return _buildGameCard(game);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: ElevatedButton(
        onPressed: () {
          print('$title filter selected');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.grey.shade700 : Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildGameCard(dynamic game) {
    final String imageUrl = game.coverUrl;
    final String name = game is GameSummary ? game.name : 'Top Rated Game';
    final String score = game is GameSummary ? (game.releaseYear % 100).toString() : '85';
    final int scoreNum = int.parse(score);
    final scoreColor = scoreNum >= 70 ? const Color(0xFF2ECC71) : Colors.grey;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameDetailPage(id: game.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.videogame_asset,
                          color: Colors.white54,
                          size: 50,
                        ),
                      );
                    },
                  ),
                  // Score Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        score,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Game Title
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.visibility_off,
                onTap: () => _showHideConfirmation(game),
              ),
              _buildActionButton(
                icon: Icons.check,
                onTap: () => _showRatingDialog(game),
              ),
              _buildActionButton(
                icon: Icons.favorite_border,
                onTap: () => _saveGame(game),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _showHideConfirmation(dynamic game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Hide Game',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to hide "${game is GameSummary ? game.name : 'this game'}"? You won\'t see it again in your recommendations.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hide'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement hide functionality with backend
      setState(() {
        games.remove(game);
      });
    }
  }

  Future<void> _showRatingDialog(dynamic game) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
        ),
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  "I've Seen This",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Game Cover Image
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(game.coverUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Game Title
                Text(
                  game is GameSummary ? game.name : 'Rate this game',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Release Year
                Text(
                  "(${game is GameSummary ? game.releaseYear : '2024'})",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // Rating Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRatingOption('Awful', const Color(0xFF8E8E93), 0.8),
                      _buildRatingOption('Meh', const Color(0xFFAEA79F), 1.0),
                      _buildRatingOption('Good', const Color(0xFFFFA500), 1.2),
                      _buildRatingOption('Amazing', const Color(0xFFFF6B00), 0.8),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Haven't Seen Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2C2C2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Haven't Seen",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            // Close Button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOption(String label, Color color, double scale) {
    final baseSize = 60.0;
    final size = baseSize * scale;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Implement rating functionality
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(size / 2),
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

  Future<void> _saveGame(dynamic game) async {
    // TODO: Implement save functionality with backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${game is GameSummary ? game.name : 'game'} to your saved list',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
