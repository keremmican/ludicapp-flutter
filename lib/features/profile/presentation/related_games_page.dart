import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/top_games_cover.dart';

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
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  SortOption _currentSort = SortOption.topRated;

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
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.53,
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
