import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/top_games_cover.dart';
import 'package:ludicapp/core/widgets/rating_modal.dart';

enum SortOption {
  topRated,
  recentlyAdded,
}

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
  Set<int> savedGames = {};
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  SortOption _currentSort = SortOption.topRated;
  int? _userRating;

  @override
  void initState() {
    super.initState();
    print('Initializing RelatedGamesPage for: ${widget.categoryTitle}');
    _loadGames();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      if (widget.categoryTitle == 'New Releases') {
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
        final response = await _gameRepository.fetchGamesByGenre(
          genre: widget.categoryTitle,
          page: _currentPage,
          size: _pageSize,
          sortByRating: _currentSort == SortOption.topRated,
        );

        if (!mounted) return;
        handleResponse(response);
      }
      else if (themes.contains(widget.categoryTitle)) {
        print('Fetching games for theme: ${widget.categoryTitle} - Page: $_currentPage');
        final response = await _gameRepository.fetchGamesByTheme(
          theme: widget.categoryTitle,
          page: _currentPage,
          size: _pageSize,
          sortByRating: _currentSort == SortOption.topRated,
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

  void handleResponse(PageableResponse response) {
    setState(() {
      games.addAll(response.content);
      _hasMore = !response.last;
      _isLoading = false;
    });
    
    print('Response received: ${response.content.length} items');
    print('Updated state - Total games: ${games.length}, hasMore: $_hasMore');
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Sıralama Butonu
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: PopupMenuButton<SortOption>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.grey[900],
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
                  const PopupMenuItem<SortOption>(
                    value: SortOption.topRated,
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Top Rated',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<SortOption>(
                    value: SortOption.recentlyAdded,
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
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentSort == SortOption.topRated 
                          ? Icons.star 
                          : Icons.access_time,
                        color: _currentSort == SortOption.topRated 
                          ? Colors.amber 
                          : Colors.blue[300],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentSort == SortOption.topRated 
                          ? 'Top Rated' 
                          : 'Recently Added',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Diğer Filtre Butonları
            _buildFilterButton('Available to Play'),
            _buildFilterButton('Hide Rated'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          print('$title filter selected');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.grey[700] : Colors.grey[850],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
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
          _buildFilterRow(), // Yeni filtre satırı
          const SizedBox(height: 16),
          Expanded(
            child: games.isEmpty && !_isLoading
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
                      childAspectRatio: 0.51,
                    ),
                    itemCount: games.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= games.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      }
                      return _buildGameCard(games[index]);
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameSummary game) {
    final bool isSaved = savedGames.contains(game.id);
    
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Game Cover Image with Container
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      game.coverUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.error, color: Colors.white),
                        );
                      },
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
            ],
          ),
          const SizedBox(height: 8),
          // Game Title and Rating Row
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
                game.rating?.toStringAsFixed(0) ?? '--',
                style: TextStyle(
                  color: Colors.green[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isSaved) ...[
            const SizedBox(height: 4),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _showHideConfirmation(game),
                  icon: const Icon(
                    Icons.thumb_down_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  onPressed: () => _showRatingDialog(game),
                  icon: const Icon(
                    Icons.check_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  onPressed: () => _handleSaveGame(game),
                  icon: const Icon(
                    Icons.favorite_border_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ],
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

  void _showRatingDialog(dynamic game) {
    RatingModal.show(
      context,
      gameName: game is GameSummary ? game.name : 'Rate this game',
      coverUrl: game.coverUrl,
      releaseYear: game is GameSummary ? game.releaseDate : null,
      initialRating: _userRating,
      onRatingSelected: (rating) {
        setState(() {
          _userRating = rating;
        });
      },
    );
  }

  Future<void> _saveGame(dynamic game) async {
    // TODO: Implement save functionality with backend
  }

  void _showSavedNotification() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(
                Icons.favorite,
                color: Colors.red[400],
                size: 64,
              ),
            ),
          );
        },
      ),
    );

    // Automatically dismiss after 1 second
    Future.delayed(const Duration(milliseconds: 800), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _handleSaveGame(GameSummary game) async {
    await _saveGame(game);
    setState(() {
      savedGames.add(game.id);
    });
    _showSavedNotification();
  }
}
