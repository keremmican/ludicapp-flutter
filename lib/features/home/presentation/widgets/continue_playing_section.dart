import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
      decoration: BoxDecoration(
        // Use theme-aware Cupertino background
        color: CupertinoTheme.of(context).brightness == Brightness.dark
               ? CupertinoColors.darkBackgroundGray // Or secondarySystemGroupedBackground
               : CupertinoColors.white, // Or secondarySystemGroupedBackground
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: Colors.grey[850]!, width: 1.5), // Remove border
      ),
      child: Stack( // Use Stack for positioning the counter
        children: [
          Padding( // Apply padding to the main content
             padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, left: 16.0, right: 16.0), // Add right padding too
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use Cupertino Title Style directly, forcing color
                Text(
                  'Continue Playing',
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                    color: CupertinoColors.label.resolveFrom(context),
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
            top: 12, // Adjust position
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Adjust padding
              decoration: BoxDecoration(
                 // Use lighter semi-transparent grey
                 color: CupertinoColors.systemGrey.withOpacity(0.3),
                 borderRadius: BorderRadius.circular(8), // Adjust radius
              ),
              child: Text(
                '${currentlyPlayingGames.length}/$_maxGames',
                style: TextStyle(
                  // Use theme-aware secondary label color
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0), // Adjust padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Sign in to your accounts to sync the games you are currently playing.',
                textAlign: TextAlign.center,
                // Use Cupertino text style with secondary color
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Use Cupertino Button
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(CupertinoIcons.add, size: 20), // Use Cupertino icon
                    SizedBox(width: 8),
                    Text('Add Games'), // Update text
                  ],
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
                       // Use CupertinoPageRoute here as well
                       CupertinoPageRoute(
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
                      // Apply same style as GameSection cards
                      color: CupertinoTheme.of(context).brightness == Brightness.dark
                             ? CupertinoColors.darkBackgroundGray
                             : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      // boxShadow: [ // Remove shadow
                      //   ...
                      // ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: game.coverUrl ?? '',
                        fit: BoxFit.cover,
                        // Use Cupertino placeholder/error
                        placeholder: (context, url) => Container(color: CupertinoTheme.of(context).brightness == Brightness.dark
                                                                      ? CupertinoColors.systemGrey6.darkColor
                                                                      : CupertinoColors.systemGrey6.color),
                        errorWidget: (context, url, error) => Container(
                            color: CupertinoTheme.of(context).brightness == Brightness.dark
                                   ? CupertinoColors.systemGrey6.darkColor
                                   : CupertinoColors.systemGrey6.color,
                            child: const Center(child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey))),
                      ),
                    ),
                  ),
                ),

                // Remove Button ('X')
                Positioned(
                  top: -8, // Adjust position
                  right: -8,
                  child: GestureDetector(
                    onTap: () {
                      if (game.gameId != null) {
                         // Call the callback passed from HomePage
                        widget.onRemoveGamePressed(game.gameId!); 
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4), // Adjust padding
                      decoration: BoxDecoration(
                        // Use semi-transparent grey circle
                        color: CupertinoColors.systemGrey.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark, // Use Cupertino icon
                        color: CupertinoColors.white,
                        size: 12, // Adjust size
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

  // Style the "Add New" card to look like a tappable area
  Widget _buildAddNewCard(BuildContext context, double width, double height) {
    final bool isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? CupertinoColors.darkBackgroundGray // Slightly darker than main background
        : CupertinoColors.systemGrey6; // Light grey
    final Color iconColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return GestureDetector(
      onTap: widget.onAddGamesPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          // Optionally add a very subtle border if needed for contrast
          // border: Border.all(
          //   color: CupertinoColors.systemGrey4,
          //   width: 0.5,
          // ),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.add,
            color: iconColor,
            size: 35, // Slightly larger icon
          ),
        ),
      ),
    );
  }
} 