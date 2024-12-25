import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';

class RelatedGamesPage extends StatelessWidget {
  final String categoryTitle;

  const RelatedGamesPage({Key? key, required this.categoryTitle})
      : super(key: key);

  static final Map<String, List<Map<String, String>>> mockRelatedGames = {
    'Top Matches': [
      {
        'image': 'lib/assets/images/mock_games/game1.jpg',
        'name': 'Grand Theft Auto VI',
        'score': '97',
      },
      {
        'image': 'lib/assets/images/mock_games/game2.jpg',
        'name': 'Cyberpunk 2077',
        'score': '86',
      },
    ],
    'Saved': [
      {
        'image': 'lib/assets/images/mock_games/game3.jpg',
        'name': 'The Witcher 4',
        'score': '90',
      },
      {
        'image': 'lib/assets/images/mock_games/game4.jpg',
        'name': 'Halo Infinite',
        'score': '65',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final relatedGames =
        mockRelatedGames[categoryTitle] ?? <Map<String, String>>[];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: Colors.black,
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
                  _buildFilterButton('Recently Saved', isSelected: true),
                  _buildFilterButton('Available to Stream'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Game Grid
          relatedGames.isNotEmpty
              ? Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2 / 3,
                    ),
                    itemCount: relatedGames.length,
                    itemBuilder: (context, index) {
                      final game = relatedGames[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to game detail page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameDetailPage(game: game),
                            ),
                          );
                        },
                        child: _buildGameCard(game),
                      );
                    },
                  ),
                )
              : const Center(
                  child: Text(
                    'No games available in this category.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildGameCard(Map<String, String> game) {
    final score = int.parse(game['score']!);
    final scoreColor = score >= 70 ? Colors.green : Colors.grey;

    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Image.asset(
                game['image']!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Game Title
                Expanded(
                  child: Text(
                    game['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),

                // Score
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    game['score']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
