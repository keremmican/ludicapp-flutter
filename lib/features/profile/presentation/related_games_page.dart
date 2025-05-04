import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/top_games_cover.dart';
import 'package:ludicapp/core/widgets/rating_modal.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/core/providers/blurred_background_provider.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/services/category_service.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';
import 'package:ludicapp/services/model/response/user_game_actions.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum SortOption {
  topRatedDesc,
  topRatedAsc,
  recentlyAddedAsc,
  oldOnesDesc,
}

class RelatedGamesPage extends StatefulWidget {
  final String categoryTitle;
  final int? popularityTypeId;
  final int? platformId;
  final int? genreId;
  final int? themeId;
  final int? libraryId;

  const RelatedGamesPage({
    Key? key, 
    required this.categoryTitle,
    this.popularityTypeId,
    this.platformId,
    this.genreId,
    this.themeId,
    this.libraryId,
  }) : super(key: key);

  @override
  State<RelatedGamesPage> createState() => _RelatedGamesPageState();
}

class _RelatedGamesPageState extends State<RelatedGamesPage> {
  final GameRepository _gameRepository = GameRepository();
  final CategoryService _categoryService = CategoryService();
  final LibraryRepository _libraryRepository = LibraryRepository();
  final HomeController _homeController = HomeController();
  List<GameSummary> games = [];
  Map<int, GameDetailWithUserInfo> gameDetailsMap = {};
  Set<int> savedGames = {};
  Set<int> ratedGames = {};
  Map<int, int> userRatings = {};
  bool _isLoading = false;
  bool _isInitialLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  SortOption _currentSort = SortOption.topRatedDesc;
  bool _availableToPlay = false;
  bool _hideRated = false;

  @override
  void initState() {
    super.initState();
    print('Initializing RelatedGamesPage for: ${widget.categoryTitle}');
    _ensureCategoriesLoaded();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureCategoriesLoaded() async {
    setState(() {
      _isInitialLoading = true;
    });
    if (!_categoryService.isInitialized) {
      await _categoryService.initialize();
    }
    await _loadGames();
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _initialLoad() async {
    print('Starting initial load for: ${widget.categoryTitle}');
    setState(() {
      games = [];
      _currentPage = 0;
      _hasMore = true;
    });
    return _loadGames();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.9;

    if (currentScroll >= threshold && !_isLoading && _hasMore) {
      print('Scroll threshold reached. Loading next page.');
      _currentPage++;
      _loadGames();
    }
  }

  Future<void> _loadGames() async {
    if (_isLoading || (!_hasMore && _currentPage > 0)) return;

    setState(() {
      _isLoading = true;
      if (_currentPage == 0) _isInitialLoading = true;
    });

    try {
      if (widget.libraryId != null) {
        print('Fetching games for library: ${widget.libraryId} - Page: $_currentPage');
        final response = await _libraryRepository.getGamesByLibraryId(
          widget.libraryId!,
          page: _currentPage,
          size: _pageSize,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (widget.platformId != null) {
        print('Fetching games for platform: ${widget.platformId} - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByPlatformWithUserInfo(
          platformId: widget.platformId!,
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (widget.genreId != null) {
        print('Fetching games for genre: ${widget.genreId} - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByGenreWithUserInfo(
          genreId: widget.genreId!,
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (widget.themeId != null) {
        print('Fetching games for theme: ${widget.themeId} - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByThemeWithUserInfo(
          themeId: widget.themeId!,
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (widget.popularityTypeId != null) {
        print('Fetching games for popularity type: ${widget.popularityTypeId} - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final response = await _gameRepository.fetchGamesByPopularityTypeWithUserInfo(
          popularityType: widget.popularityTypeId!,
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (widget.categoryTitle == 'New Releases') {
        print('Fetching new releases - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final response = await _gameRepository.fetchNewReleasesWithUserInfo(
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );
        
        if (!mounted) return;
        handleResponseWithUserInfo(response);
      } 
      else if (widget.categoryTitle == 'Top Rated') {
        print('Fetching top rated games - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final response = await _gameRepository.fetchTopRatedGamesWithUserInfo(
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (widget.categoryTitle == 'Coming Soon') {
        print('Fetching coming soon games - Page: $_currentPage, hideRated: $_hideRated');
        final response = await _gameRepository.fetchComingSoonWithUserInfo(
          page: _currentPage,
          pageSize: _pageSize,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (genres.contains(widget.categoryTitle)) {
        print('Fetching games for genre: ${widget.categoryTitle} - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByGenreWithUserInfo(
          genreId: _getGenreId(widget.categoryTitle),
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else if (themes.contains(widget.categoryTitle)) {
        print('Fetching games for theme: ${widget.categoryTitle} - Page: $_currentPage, availableToPlay: $_availableToPlay, hideRated: $_hideRated');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByThemeWithUserInfo(
          themeId: _getThemeId(widget.categoryTitle),
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
          availableToPlay: _availableToPlay,
          hideRated: _hideRated,
        );

        if (!mounted) return;
        handleResponseWithUserInfo(response);
      }
      else {
        print('Unknown category: ${widget.categoryTitle}');
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      print('Error loading games: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  (String, String) _getSortParams(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.topRatedDesc:
        return ('rating', 'DESC');
      case SortOption.topRatedAsc:
        return ('rating', 'ASC');
      case SortOption.recentlyAddedAsc:
        return ('releaseDate', 'ASC');
      case SortOption.oldOnesDesc:
        return ('releaseDate', 'DESC');
    }
  }

  void handleResponse(PageableResponse<GameSummary> response) {
    setState(() {
      if (_currentPage == 0) {
        games = response.content;
      } else {
        games.addAll(response.content);
      }
      _hasMore = !response.last;
      _currentPage++;
      _isLoading = false;
      _isInitialLoading = false;
    });
  }

  void handleResponseWithUserInfo(PagedGameWithUserResponse response) {
    // Extract newly added games BEFORE updating the main list
    final newGames = response.content.map((gameWithUser) {
      _processUserGameInfo(gameWithUser);
      gameDetailsMap[gameWithUser.gameDetails.id] = gameWithUser;
      return gameWithUser.gameDetails;
    }).toList();

    // Initiate pre-caching for new games in the background
    if (mounted) {
      for (final game in newGames) {
        if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
           try {
             precacheImage(CachedNetworkImageProvider(game.coverUrl!), context)
               .catchError((e) => print('BG Pre-cache Error (Cover ${game.id}): $e'));
             print('BG Pre-cache Initiated (Cover ${game.id})');
           } catch (e) {
             print('Sync BG Pre-cache Error (Cover ${game.id}): $e');
           }
        }
        if (game.screenshots.isNotEmpty) {
           try {
             precacheImage(CachedNetworkImageProvider(game.screenshots[0]), context)
               .catchError((e) => print('BG Pre-cache Error (SS ${game.id}): $e'));
             print('BG Pre-cache Initiated (SS ${game.id})');
           } catch (e) {
             print('Sync BG Pre-cache Error (SS ${game.id}): $e');
           }
        }
      }
    }

    setState(() {
      if (_currentPage == 0) {
        games = newGames; // Assign the already processed new games
      } else {
        games.addAll(newGames); // Add the already processed new games
      }
      _hasMore = response.last != null ? !response.last! : false;
      // Increment page number AFTER processing the current page's response
      // _currentPage++; // Moved page increment to _loadGames initiation in _onScroll
      _isLoading = false;
      _isInitialLoading = false;
    });
  }

  void _processUserGameInfo(GameDetailWithUserInfo gameWithUser) {
    final gameId = gameWithUser.gameDetails.id;
    final userActions = gameWithUser.userActions;
    
    if (userActions != null) {
      if (userActions.userRating != null) {
        userRatings[gameId] = userActions.userRating!;
        ratedGames.add(gameId);
      }
      
      if (userActions.isSaved == true) {
        savedGames.add(gameId);
      }
    }
  }

  int _getGenreId(String genreName) {
    final genre = _categoryService.genres.firstWhere(
      (g) => g.name == genreName,
      orElse: () => throw Exception('Genre not found: $genreName'),
    );
    return genre.id;
  }

  int _getThemeId(String themeName) {
    final theme = _categoryService.themes.firstWhere(
      (t) => t.name == themeName,
      orElse: () => throw Exception('Theme not found: $themeName'),
    );
    return theme.id;
  }

  static const List<String> genres = [
    'Point-and-click',
    'Fighting',
    'Shooter',
    'Music',
    'Platform',
    'Puzzle',
    'Racing',
    'Real Time Strategy (RTS)',
    'Role-playing (RPG)',
    'Simulator',
    'Sport',
    'Strategy',
    'Turn-based strategy (TBS)',
    'Tactical',
    'Hack and slash/Beat \'em up',
    'Quiz/Trivia',
    'Pinball',
    'Adventure',
    'Indie',
    'Arcade',
    'Visual Novel',
    'Card & Board Game',
    'MOBA',
  ];

  static const List<String> themes = [
    'Drama',
    'Non-fiction',
    'Sandbox',
    'Educational',
    'Kids',
    'Open world',
    'Warfare',
    'Party',
    '4X (explore, expand, exploit, and exterminate)',
    'Erotic',
    'Mystery',
    'Action',
    'Fantasy',
    'Science fiction',
    'Horror',
    'Thriller',
    'Survival',
    'Historical',
    'Stealth',
    'Comedy',
    'Business',
    'Romance',
  ];

  Widget _buildFilterRow() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          // Sorting Button - Only show for genres and themes
          if (genres.contains(widget.categoryTitle) || themes.contains(widget.categoryTitle))
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<SortOption>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: AppTheme.surfaceDark,
                elevation: 8,
                offset: const Offset(0, 40),
                onSelected: (SortOption result) {
                  setState(() {
                    _currentSort = result;
                    _currentPage = 0;
                    games = [];
                    _hasMore = true;
                    _loadGames();
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
                  if (_currentSort != SortOption.topRatedDesc)
                    const PopupMenuItem<SortOption>(
                      value: SortOption.topRatedDesc,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Top Rated (High to Low)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  if (_currentSort != SortOption.topRatedAsc)
                    const PopupMenuItem<SortOption>(
                      value: SortOption.topRatedAsc,
                      child: Row(
                        children: [
                          Icon(Icons.star_half, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Top Rated (Low to High)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  if (_currentSort != SortOption.recentlyAddedAsc)
                    PopupMenuItem<SortOption>(
                      value: SortOption.recentlyAddedAsc,
                      child: Row(
                        children: [
                          Icon(Icons.access_time, 
                            color: Colors.blue[300], 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recently Added',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  if (_currentSort != SortOption.oldOnesDesc)
                    PopupMenuItem<SortOption>(
                      value: SortOption.oldOnesDesc,
                      child: Row(
                        children: [
                          Icon(Icons.history, 
                            color: Colors.grey[400], 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Old Ones',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSortIcon(_currentSort),
                        color: _getSortIconColor(_currentSort),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSortText(_currentSort),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Other Filter Buttons - Show for all categories
          _buildFilterButton(
            'Available to Play',
            isActive: _availableToPlay,
            onTap: widget.categoryTitle != 'Coming Soon' ? () {
              setState(() {
                _availableToPlay = !_availableToPlay;
                _currentPage = 0;
                games = [];
                _hasMore = true;
                _loadGames();
              });
            } : null,
          ),
          _buildFilterButton(
            'Hide Rated',
            isActive: _hideRated,
            onTap: () {
              setState(() {
                _hideRated = !_hideRated;
                _currentPage = 0;
                games = [];
                _hasMore = true;
                _loadGames();
              });
            },
          ),
        ],
      ),
    );
  }

  IconData _getSortIcon(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.topRatedDesc:
      case SortOption.topRatedAsc:
        return sortOption == SortOption.topRatedDesc ? Icons.star : Icons.star_half;
      case SortOption.recentlyAddedAsc:
        return Icons.access_time;
      case SortOption.oldOnesDesc:
        return Icons.history;
    }
  }

  Color _getSortIconColor(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.topRatedDesc:
      case SortOption.topRatedAsc:
        return Colors.amber;
      case SortOption.recentlyAddedAsc:
        return Colors.blue[300]!;
      case SortOption.oldOnesDesc:
        return Colors.grey[400]!;
    }
  }

  String _getSortText(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.topRatedDesc:
        return 'Top Rated (High to Low)';
      case SortOption.topRatedAsc:
        return 'Top Rated (Low to High)';
      case SortOption.recentlyAddedAsc:
        return 'Recently Added';
      case SortOption.oldOnesDesc:
        return 'Old Ones';
    }
  }

  Widget _buildFilterButton(String title, {bool isActive = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 30,
          constraints: const BoxConstraints(minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(),
          const SizedBox(height: 16),
          Expanded(
            child: _isInitialLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    games.isEmpty && !_isLoading
                      ? const Center(
                          child: Text(
                            'No games available in this category.',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _initialLoad,
                          color: Colors.white,
                          backgroundColor: Colors.grey[900],
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.54,
                            ),
                            itemCount: games.length + (_hasMore && _isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= games.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return GameCard(
                                game: games[index],
                                gameDetail: gameDetailsMap[games[index].id],
                                onSave: _handleSaveGame,
                                onRate: _showRatingDialog,
                                onHide: _handleHideGame,
                                onGameUpdated: (gameId, returnedGame) async {
                                  print('RelatedGamesPage - Returned from GameDetailPage for gameId=$gameId. Fetching fresh details...');
                                  // NOTE: We ignore returnedGame.userActions regarding isInCustomList
                                  // because AddToListModal doesn't return its final state.

                                  if (!mounted) return; // Check if the widget is still in the tree

                                  try {
                                    // Fetch the *latest* details from the backend
                                    final GameDetailWithUserInfo freshDetails = await _gameRepository.fetchGameDetailsWithUserInfo(gameId);

                                    if (mounted) {
                                      print('RelatedGamesPage - Fresh details received for gameId=$gameId: userActions=${freshDetails.userActions}');

                                      // Update the central map with the fresh data
                                      gameDetailsMap[gameId] = freshDetails;

                                      // Reprocess user info (for saved/rated sets - might be slightly redundant if only list changed, but safe)
                                      _processUserGameInfo(freshDetails);

                                      // Trigger UI update using the fresh details
                                      setState(() {
                                         // Force rebuild of the GameCard by updating the GameSummary reference
                                         // This ensures the GridView item rebuilds.
                                         final gameIndex = games.indexWhere((game) => game.id == gameId);
                                         if (gameIndex != -1) {
                                           // Recreate the GameSummary object from the fresh details using the correct constructor
                                           games[gameIndex] = GameSummary.fromGameDetailWithUserInfo(freshDetails);
                                         }
                                         print('RelatedGamesPage - State updated with fresh details for gameId=$gameId');
                                      });
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      print('RelatedGamesPage - Error fetching fresh details for gameId=$gameId: $e');
                                      // Optionally show an error message to the user
                                      ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(content: Text('Could not refresh game status for ${games.firstWhere((g) => g.id == gameId, orElse: () => GameSummary(
                                           id: gameId, 
                                           name: 'Game', 
                                           slug: 'unknown-game',
                                           genres: [],
                                           themes: [],
                                           platforms: [],
                                           companies: [],
                                           screenshots: [],
                                           gameVideos: [],
                                           franchises: [],
                                           gameModes: [],
                                           playerPerspectives: [],
                                           languageSupports: [],
                                         )).name}.')),
                                      );
                                      // The UI will remain in its previous (potentially incorrect optimistic) state
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(GameSummary game) {
    // Pass null for initial data as it's not readily available here
    // Or fetch it like in library_detail_page if needed
    RatingModal.show(
      context,
      gameName: game.name,
      coverUrl: game.coverUrl ?? '',
      gameId: game.id,
      // Pass the correct parameter name
      initialUserGameRating: null, // Or fetch data first
      onUpdateComplete: (updatedRating) {
        if (mounted) {
        setState(() {
            // Update local state maps
            if (updatedRating.rating != null) {
              userRatings[game.id] = updatedRating.rating!;
            ratedGames.add(game.id);
          } else {
            userRatings.remove(game.id);
            ratedGames.remove(game.id);
            }
            // Update other local states if needed (e.g., comment)
            
            // Find the game in the gameDetailsMap and update its userActions
            if (gameDetailsMap.containsKey(game.id)) {
                // Get existing details
                final existingDetails = gameDetailsMap[game.id]!;
                 // Create updated actions using copyWith on existing actions (or create new)
                final updatedUserActions = (existingDetails.userActions ?? const UserGameActions()).copyWith(
                    userRating: updatedRating.rating,
                    comment: updatedRating.comment,
                    isSaved: savedGames.contains(game.id), // Keep local saved status
                    isRated: updatedRating.rating != null, // Update isRated based on new rating
                    playStatus: updatedRating.playStatus,
                    completionStatus: updatedRating.completionStatus,
                    playtimeInMinutes: updatedRating.playtimeInMinutes,
                    // Keep other fields like isHidden, isInCustomList from existing if needed
                    isHidden: existingDetails.userActions?.isHidden,
                    isInCustomList: existingDetails.userActions?.isInCustomList,
              );
                // Update the map with the original gameDetails and the new userActions
              gameDetailsMap[game.id] = GameDetailWithUserInfo(
                    gameDetails: existingDetails.gameDetails,
                    userActions: updatedUserActions,
              );
            }

          });
          // Update HomeController if necessary
          _homeController.updateGameRatingState(game.id, updatedRating.rating);
          _homeController.updateGameComment(game.id, updatedRating.comment);
              }
      },
    );
  }

  Future<void> _handleSaveGame(GameSummary game) async {
    final gameDetail = gameDetailsMap[game.id];
    final isSaved = gameDetail?.userActions?.isSaved ?? false;

    try {
      final bool success = isSaved 
        ? await _libraryRepository.unsaveGame(game.id)
        : await _libraryRepository.saveGame(game.id);

      if (success && mounted) {
        setState(() {
          // Update the game's userActions in gameDetailsMap
          if (gameDetail != null) {
            final updatedActions = gameDetail.userActions?.copyWith(isSaved: !isSaved, isInCustomList: gameDetail.userActions?.isInCustomList) ??
                UserGameActions(isSaved: !isSaved, isInCustomList: gameDetail.userActions?.isInCustomList);
            gameDetailsMap[game.id] = GameDetailWithUserInfo(
              gameDetails: gameDetail.gameDetails,
              userActions: updatedActions,
            );
          }
        });
        
        // Update in HomeController for other pages
        _homeController.updateGameSaveState(game.id, !isSaved);

        // Show save animation if game is being saved (not unsaved)
        if (!isSaved) {
          _showSavedNotification();
        }
      }
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<void> _handleHideGame(GameSummary gameToHide) async {
    await _showHideConfirmation(context, gameToHide);
  }

  Future<void> _showHideConfirmation(BuildContext context, GameSummary gameToHide) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Hide Game',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to hide "${gameToHide.name}"? You won\'t see it again in your recommendations.',
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

    if (confirmed == true && mounted) {
      // Call backend to hide the game
      try {
        final success = await _libraryRepository.hideGame(gameToHide.id);
        if (success) {
          setState(() {
            games.removeWhere((game) => game.id == gameToHide.id);
            gameDetailsMap.remove(gameToHide.id); // Also remove from details map
          });
          // Update HomeController
          _homeController.updateGameHiddenState(gameToHide.id, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${gameToHide.name}" hidden.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to hide game. Please try again.')),
          );
        }
      } catch (e) {
        print('Error hiding game: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error hiding game: ${e.toString()}')),
        );
      }
    }
  }

  void _showSavedNotification() {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 40,
        left: MediaQuery.of(context).size.width / 2 - 40,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red[400],
                    size: 40,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }
}

class GameCard extends StatefulWidget {
  final GameSummary game;
  final GameDetailWithUserInfo? gameDetail;
  final Function(GameSummary) onSave;
  final Function(GameSummary) onRate;
  final Function(GameSummary) onHide;
  final Function(int, Game) onGameUpdated;

  const GameCard({
    Key? key,
    required this.game,
    this.gameDetail,
    required this.onSave,
    required this.onRate,
    required this.onHide,
    required this.onGameUpdated,
  }) : super(key: key);

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool get isSaved => widget.gameDetail?.userActions?.isSaved ?? false;
  bool get isRated => widget.gameDetail?.userActions?.isRated ?? false;
  bool get isInCustomList => widget.gameDetail?.userActions?.isInCustomList ?? false;

  @override
  Widget build(BuildContext context) {
    print('GameCard build - gameId=${widget.game.id}, isSaved=$isSaved, isRated=$isRated, userActions=${widget.gameDetail?.userActions}');
    
    return GestureDetector(
      onTap: () {
        ImageProvider? coverProvider;
        // Create provider and initiate pre-cache WITHOUT awaiting
        if (widget.game.coverUrl != null && widget.game.coverUrl!.isNotEmpty) {
          coverProvider = CachedNetworkImageProvider(widget.game.coverUrl!);
          try {
            if (mounted) {
              precacheImage(coverProvider, context)
                  .catchError((e) => print('Error pre-caching cover: $e')); 
              print('Initiated pre-cache for cover: ${widget.game.name}');
            }
          } catch (e) { 
            print('Sync error initiating cover pre-cache: $e');
          }
        }
        // Pre-cache first screenshot (fire-and-forget)
        if (widget.game.screenshots.isNotEmpty) {
           try {
            if (mounted) {
              precacheImage(CachedNetworkImageProvider(widget.game.screenshots[0]), context)
                  .catchError((e) => print('Error pre-caching screenshot: $e')); 
              print('Initiated pre-cache for screenshot: ${widget.game.name}');
            }
          } catch (e) { 
             print('Sync error initiating screenshot pre-cache: $e');
          }
        }

        // Navigate immediately, passing the provider
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameDetailPage(
              game: widget.gameDetail != null 
                ? Game.fromGameDetailWithUserInfo(widget.gameDetail!)
                : Game.fromGameSummary(widget.game),
              initialCoverProvider: coverProvider, // Pass the provider
            ),
          ),
        ).then((result) {
          if (result != null && result is Game) {
            // GameDetailPage'den dönen güncellenmiş oyun bilgisini parent'a ilet
            widget.onGameUpdated(widget.game.id, result);
            
            // State'i güncelle
            setState(() {});
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Cover Image with Container
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: widget.game.coverUrl ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        fadeInDuration: const Duration(milliseconds: 0),
                        placeholder: (context, url) => Container(color: Colors.grey[800]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.error, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  if (isSaved)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  if (isInCustomList)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Game Title and Rating Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.game.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.game.totalRating?.toStringAsFixed(0) ?? '--',
                        style: TextStyle(
                          color: Colors.green[400],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Action Buttons - Always show but with opacity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Opacity(
                        opacity: (!isSaved && !isRated) ? 1.0 : 0.0,
                        child: IconButton(
                          onPressed: (!isSaved && !isRated) ? () {
                            widget.onHide(widget.game);
                          } : null,
                          icon: const Icon(
                            Icons.thumb_down_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Opacity(
                        opacity: (!isSaved && !isRated) ? 1.0 : 0.0,
                        child: IconButton(
                          onPressed: (!isSaved && !isRated) ? () {
                            widget.onRate(widget.game);
                          } : null,
                          icon: const Icon(
                            Icons.check_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Opacity(
                        opacity: (!isSaved && !isRated) ? 1.0 : 0.0,
                        child: IconButton(
                          onPressed: (!isSaved && !isRated) ? () {
                            widget.onSave(widget.game);
                          } : null,
                          icon: const Icon(
                            Icons.favorite_border_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
