import 'package:flutter/material.dart';
import 'package:ludicapp/theme/app_theme.dart';
// Remove provider import if not used elsewhere
// import 'package:provider/provider.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_game_to_library_modal.dart';
import 'package:ludicapp/services/repository/library_repository.dart'; // Remove için

// Change to StatefulWidget
class ContinuePlayingSection extends StatefulWidget { 
  final VoidCallback onAddGamesPressed;
  final Function(int) onRemoveGamePressed; 

  const ContinuePlayingSection({
    Key? key,
    required this.onAddGamesPressed,
    required this.onRemoveGamePressed,
  }) : super(key: key);

  @override
  State<ContinuePlayingSection> createState() => _ContinuePlayingSectionState();
}

// Create State class
class _ContinuePlayingSectionState extends State<ContinuePlayingSection> { 
  // Get singleton instance
  final HomeController _homeController = HomeController();
  static const int _maxGames = 10; // Max game count constant

  @override
  void initState() {
    super.initState();
    // Add listener
    _homeController.addListener(_onHomeControllerUpdate);
  }

  @override
  void dispose() {
    // Remove listener
    _homeController.removeListener(_onHomeControllerUpdate);
    super.dispose();
  }

  // Method to trigger rebuild on controller change
  void _onHomeControllerUpdate() {
    // Check if widget is still mounted before calling setState
    if (mounted) { 
       setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the instance directly instead of context.watch
    final List<GameSummary> currentlyPlayingSummaries = _homeController.currentlyPlayingGames;
    final List<Game> currentlyPlayingGames = currentlyPlayingSummaries
        .map<Game>((summary) => _homeController.getGameWithUserActions(summary))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      // Padding'i Stack'in içine taşıyalım veya Stack'ten sonra uygulayalım.
      // Şimdilik Stack'ten sonra uygulayalım.
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[850]!, width: 1.5),
      ),
      child: Stack( // Use Stack for positioning the counter
        children: [
          Padding( // Apply padding to the main content
             padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, left: 16.0),
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevent column from taking full stack height
              children: [
                const Text(
                  'Continue Playing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                currentlyPlayingGames.isEmpty
                    ? _buildEmptyState(context)
                    : _buildGamesList(context, currentlyPlayingGames),
              ],
             ),
          ),
          // Counter positioned at the top-right
          Positioned(
            top: 10, 
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.5),
                 borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${currentlyPlayingGames.length}/$_maxGames',
                style: TextStyle(
                  color: Colors.grey[300], 
                  fontSize: 11, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, bottom: 8.0), // İçeriği ortalamak için padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Sign in to your accounts to sync the games you are currently playing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, // Biraz daha küçük metin
              color: Colors.grey,
              height: 1.4, // Satır aralığı
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Continue Playing'),
            style: ElevatedButton.styleFrom(
              // Arka plan rengini temadan al (opaklık ayarlı)
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
              foregroundColor: Theme.of(context).colorScheme.onPrimary, // Metin/ikon rengi
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'LeagueSpartan',
              ),
            ),
            onPressed: widget.onAddGamesPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(BuildContext context, List<Game> games) {
    final cardWidth = MediaQuery.of(context).size.width * 0.30;
    final cardHeight = cardWidth * 1.35;
    final bool canAddMore = games.length < _maxGames; 

    return SizedBox(
      height: cardHeight, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: games.length + (canAddMore ? 1 : 0), 
        padding: const EdgeInsets.only(right: 16.0), 
        itemBuilder: (context, index) {
          // If we can add more and it's the first item, show AddNewCard
          if (canAddMore && index == 0) { 
            return Padding(
              padding: const EdgeInsets.only(right: 12), 
              child: _buildAddNewCard(context, cardWidth, cardHeight),
            );
          }
          
          // Adjust index to get the correct game from the list
          // If AddNewCard is shown, game index is index - 1, otherwise it's just index
          final gameIndex = canAddMore ? index - 1 : index;
          final game = games[gameIndex];
          
          // Build the game card (existing logic)
          return Padding(
            padding: const EdgeInsets.only(right: 12), 
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Game Card GestureDetector
                GestureDetector(
                  onTap: () {
                    // Navigate to GameDetailPage
                    ImageProvider? coverProvider;
                    if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
                       coverProvider = CachedNetworkImageProvider(game.coverUrl!);
                       // Optional: Pre-cache the image for smoother transition
                       // precacheImage(coverProvider, context);
                    }
                    Navigator.push(
                       context,
                       MaterialPageRoute(
                          builder: (context) => GameDetailPage(
                            // Pass the full Game object
                            game: game, 
                            initialCoverProvider: coverProvider,
                          ),
                       ),
                    );
                  },
                  child: Container(
                    width: cardWidth, 
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                       boxShadow: [ // Daha belirgin gölge
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: game.coverUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[850]),
                        errorWidget: (context, url, error) => Container(
                            color: Colors.grey[850],
                            child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey))), // Hata ikonu
                      ),
                    ),
                  ),
                ),

                // Remove Button ('X')
                Positioned(
                  top: -6, 
                  right: -6, 
                  child: GestureDetector(
                    onTap: () {
                      if (game.gameId != null) {
                         // Call the callback passed from HomePage
                        widget.onRemoveGamePressed(game.gameId!); 
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65), // Daha görünür arkaplan
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1) // İnce border
                      ),
                      child: const Icon(
                        Icons.close_rounded, // Daha yuvarlak ikon
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // New helper method for the "Add New" card
  Widget _buildAddNewCard(BuildContext context, double width, double height) {
    return GestureDetector(
      onTap: widget.onAddGamesPressed, // Trigger the add games action
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(10),
          border: Border.all( // Dashed border for distinction
            color: Colors.grey[700]!, 
            width: 1.5,
            // Consider using a dashed border package if needed for true dashes
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            color: Colors.grey[500],
            size: 40,
          ),
        ),
      ),
    );
  }
} 