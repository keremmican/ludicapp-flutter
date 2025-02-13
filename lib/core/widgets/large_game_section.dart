import 'package:flutter/material.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/core/widgets/large_game_card.dart';

class LargeGameSection extends StatelessWidget {
  final String title;
  final List<Game> games;
  final Function(Game) onGameTap;

  const LargeGameSection({
    Key? key,
    required this.title,
    required this.games,
    required this.onGameTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 270, // Daha küçük bir height değeri
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (context, index) {
              return LargeGameCard(
                game: games[index],
                onTap: () => onGameTap(games[index]),
              );
            },
          ),
        ),
      ],
    );
  }
} 