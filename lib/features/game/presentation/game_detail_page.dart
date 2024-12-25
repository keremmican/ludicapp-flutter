import 'package:flutter/material.dart';

class GameDetailPage extends StatelessWidget {
  final Map<String, String> game; // Game details passed from RecommendationPage

  const GameDetailPage({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extracting game details
    String image = game['image'] ?? 'lib/assets/images/mock_games/game1.jpg';
    String name = game['name'] ?? 'Unknown Game';
    String genre = game['genre'] ?? 'Unknown Genre';
    String releaseYear = game['releaseYear'] ?? 'Unknown Year';
    String developer = game['developer'] ?? 'Unknown Developer';
    String publisher = game['publisher'] ?? 'Unknown Publisher';
    String metacritic = game['metacritic'] ?? 'N/A';
    String imdb = game['imdb'] ?? 'N/A';
    String matchPoint = game['matchPoint'] ?? '0';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image and Trailer Button
              Stack(
                children: [
                  Image.asset(
                    image, // Dynamic game image
                    height: 220, // Reduced height
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 20,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      children: const [
                        Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Play Trailer',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Game Info Section
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match Percentage
                    Row(
                      children: [
                        Text(
                          '$matchPoint% Match',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Game Title
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Genre, Age Rating, and Year
                    Text(
                      '$genre • 18+ • $releaseYear',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),

                    const SizedBox(height: 15),

                    // "Play Game" Button
                    SizedBox(
                      width: double.infinity, // Full width button
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Action for playing the game
                          // You can integrate game launching functionality here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424242), // Dark gray
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text(
                          'Play Game',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Game Description
                    const Text(
                      'In Night City, immerse yourself in a vast, futuristic world filled with intriguing characters, high-tech gadgets, and moral dilemmas.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),

                    const SizedBox(height: 10),

                    // Starring (Developer and Publisher Info)
                    Text(
                      'Developer: $developer\nPublisher: $publisher',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Action Buttons (Share, Hide, etc.)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.share, 'Share'),
                    _buildActionButton(Icons.visibility_off, 'Hide'),
                    _buildActionButton(Icons.check, 'Played'),
                    _buildActionButton(Icons.favorite_border, 'Save'),
                    _buildActionButton(Icons.schedule, 'Playing'),
                  ],
                ),
              ),

              const Divider(color: Colors.grey),

              // Ratings Section
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRating(metacritic, 'Metacritic'),
                    _buildRating(imdb, 'IMDb'),
                  ],
                ),
              ),

              const Divider(color: Colors.grey),

              // Reviews Section
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Player Reviews',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildReview(
                        'JohnDoe123', 4, 'Amazing graphics and engaging storyline.'),
                    const SizedBox(height: 10),
                    _buildReview(
                        'GamerGirl89', 5, 'Loved the open-world experience!'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildRating(String score, String label) {
    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildReview(String username, int stars, String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < stars ? Icons.star : Icons.star_border,
              color: index < stars ? Colors.amber : Colors.grey,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          comment,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
