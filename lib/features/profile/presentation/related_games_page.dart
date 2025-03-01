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

  const RelatedGamesPage({
    Key? key, 
    required this.categoryTitle,
    this.popularityTypeId,
    this.platformId,
    this.genreId,
    this.themeId,
  }) : super(key: key);

  @override
  State<RelatedGamesPage> createState() => _RelatedGamesPageState();
}

class _RelatedGamesPageState extends State<RelatedGamesPage> {
  final GameRepository _gameRepository = GameRepository();
  final CategoryService _categoryService = CategoryService();
  List<GameSummary> games = [];
  Set<int> savedGames = {};  // Changed from Map to Set
  Set<int> ratedGames = {};  // Changed from Map to Set
  Map<int, int> userRatings = {};  // gameId -> rating
  bool _isLoading = false;
  bool _isInitialLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  SortOption _currentSort = SortOption.topRatedDesc;

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
    if (_isLoading || !_hasMore) {
      print('Skipping load: isLoading=$_isLoading, hasMore=$_hasMore');
      return;
    }

    print('Loading games for ${widget.categoryTitle} - Page: $_currentPage');
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.platformId != null) {
        print('Fetching games for platform: ${widget.platformId} - Page: $_currentPage');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByPlatform(
          platformId: widget.platformId!,
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (widget.genreId != null) {
        print('Fetching games for genre ID: ${widget.genreId} - Page: $_currentPage');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByGenre(
          genreId: widget.genreId!,
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (widget.themeId != null) {
        print('Fetching games for theme ID: ${widget.themeId} - Page: $_currentPage');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByTheme(
          themeId: widget.themeId!,
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (widget.popularityTypeId != null) {
        print('Fetching games for popularity type: ${widget.popularityTypeId} - Page: $_currentPage');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByPopularityType(
          popularityType: widget.popularityTypeId!,
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (widget.categoryTitle == 'New Releases') {
        print('Fetching new releases - Page: $_currentPage');
        final response = await _gameRepository.fetchNewReleases(
          page: _currentPage,
          size: _pageSize,
        );
        
        if (!mounted) return;
        handleResponse(response);
      } 
      else if (widget.categoryTitle == 'Top Rated') {
        print('Fetching top rated games - Page: $_currentPage');
        final response = await _gameRepository.fetchTopRatedGames(
          page: _currentPage,
          size: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (widget.categoryTitle == 'Coming Soon') {
        print('Fetching coming soon games - Page: $_currentPage');
        final response = await _gameRepository.fetchComingSoon(
          page: _currentPage,
          size: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (genres.contains(widget.categoryTitle)) {
        print('Fetching games for genre: ${widget.categoryTitle} - Page: $_currentPage');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByGenre(
          genreId: _getGenreId(widget.categoryTitle),
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (themes.contains(widget.categoryTitle)) {
        print('Fetching games for theme: ${widget.categoryTitle} - Page: $_currentPage');
        final (sortBy, sortDirection) = _getSortParams(_currentSort);
        final response = await _gameRepository.fetchGamesByTheme(
          themeId: _getThemeId(widget.categoryTitle),
          sortBy: sortBy,
          sortDirection: sortDirection,
          page: _currentPage,
          pageSize: _pageSize,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else {
        print('Unknown category: ${widget.categoryTitle}');
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (error) {
      print('Error loading games: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
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
      games.addAll(response.content);
      _hasMore = !response.last;
      _isLoading = false;
    });
    
    print('Response received: ${response.content.length} items');
    print('Updated state - Total games: ${games.length}, hasMore: $_hasMore');
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
      height: 48,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          _buildFilterButton('Available to Play'),
          _buildFilterButton('Hide Rated'),
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

  Widget _buildFilterButton(String title, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          print('$title filter selected');
        },
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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
                                onSave: _handleSaveGame,
                                onRate: _showRatingDialog,
                                onHide: _handleHideGame,
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

  Widget _buildGameCard(GameSummary game) {
    final bool isSaved = savedGames.contains(game.id);
    final bool isRated = ratedGames.contains(game.id);
    final _backgroundProvider = BlurredBackgroundProvider();
    
    // Cache the blurred background and preload screenshots
    _backgroundProvider.cacheBackground(game.id.toString(), game.coverUrl);
    if (game.screenshots.isNotEmpty) {
      Game.preloadScreenshots(game.id, game.screenshots);
      for (final screenshot in game.screenshots) {
        _backgroundProvider.cacheBackground('${game.id}_${screenshot.hashCode}', screenshot);
      }
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameDetailPage(game: Game.fromGameSummary(game)),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.3),
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
                      child: Image.network(
                        game.coverUrl ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
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
                ],
              ),
            ),
            // Game Title and Rating Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.name,
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
                        game.totalRating?.toStringAsFixed(0) ?? '--',
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
                            _showHideConfirmation(context, game);
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
                            _showRatingDialog(game);
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
                            _handleSaveGame(game);
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

  void _showRatingDialog(GameSummary game) {
    RatingModal.show(
      context,
      gameName: game.name,
      coverUrl: game.coverUrl ?? '',
      releaseYear: game.releaseDate,
      initialRating: userRatings[game.id],
      onRatingSelected: (rating) {
        setState(() {
          userRatings[game.id] = rating;
          ratedGames.add(game.id);  // Changed from Map to Set usage
        });
      },
    );
  }

  Future<void> _handleSaveGame(GameSummary game) async {
    await _saveGame(game);
    if (mounted) {
      setState(() {
        savedGames.add(game.id);  // Changed from Map to Set usage
      });
      _showSavedNotification();
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
      // TODO: Implement hide functionality with backend
      setState(() {
        games.remove(gameToHide);  // Changed from indexWhere/removeAt to direct remove
      });
    }
  }

  void _showSavedNotification() {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 32,
        left: MediaQuery.of(context).size.width / 2 - 32,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Icon(
                Icons.favorite,
                color: Colors.red[400],
                size: 64,
              ),
            );
          },
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Automatically remove after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }

  Future<void> _saveGame(GameSummary game) async {
    // TODO: Implement save functionality with backend
  }
}

class GameCard extends StatefulWidget {
  final GameSummary game;
  final Function(GameSummary) onSave;
  final Function(GameSummary) onRate;
  final Function(GameSummary) onHide;

  const GameCard({
    Key? key,
    required this.game,
    required this.onSave,
    required this.onRate,
    required this.onHide,
  }) : super(key: key);

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool isSaved = false;
  bool isRated = false;

  @override
  Widget build(BuildContext context) {
    final _backgroundProvider = BlurredBackgroundProvider();
    
    // Cache the blurred background and preload screenshots
    _backgroundProvider.cacheBackground(widget.game.id.toString(), widget.game.coverUrl);
    if (widget.game.screenshots.isNotEmpty) {
      Game.preloadScreenshots(widget.game.id, widget.game.screenshots);
      for (final screenshot in widget.game.screenshots) {
        _backgroundProvider.cacheBackground('${widget.game.id}_${screenshot.hashCode}', screenshot);
      }
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameDetailPage(game: Game.fromGameSummary(widget.game)),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.3),
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
                      child: Image.network(
                        widget.game.coverUrl ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
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
                            setState(() {
                              isSaved = false;
                            });
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
                            setState(() {
                              isRated = true;
                            });
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
                            setState(() {
                              isSaved = true;
                            });
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
