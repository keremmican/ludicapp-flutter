import 'package:flutter/material.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/core/providers/blurred_background_provider.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';

class GameSection extends StatelessWidget {
  final String title;
  final List<Game> games;
  final Function(Game) onGameTap;
  final _backgroundProvider = BlurredBackgroundProvider();

  GameSection({
    Key? key,
    required this.title,
    required this.games,
    required this.onGameTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontally Scrolling Game Cards
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.30 * (1942/1559),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                // Cache the blurred background
                _backgroundProvider.cacheBackground(game.gameId.toString(), game.coverUrl);
                if (game.screenshots != null) {
                  for (final screenshot in game.screenshots!) {
                    _backgroundProvider.cacheBackground('${game.gameId}_${screenshot.hashCode}', screenshot);
                  }
                }
                
                return GestureDetector(
                  onTap: () => onGameTap(game),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index != games.length - 1 ? 12.0 : 0,
                    ),
                    width: MediaQuery.of(context).size.width * 0.30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        game.coverUrl ?? '',
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
