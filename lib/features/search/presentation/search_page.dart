import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/search_game.dart';
import 'package:ludicapp/services/repository/search_repository.dart';
import 'dart:async';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/features/profile/presentation/related_games_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const int _pageSize = 20;

  late final TextEditingController _searchController;
  late final SearchRepository _searchRepository;
  late final ScrollController _scrollController;
  
  List<SearchGame> _searchResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;
  Timer? _debounce;
  String _lastQuery = '';

  static const List<String> popularCategories = [
    'New Releases',
    'Top Rated',
    'Most Played',
    'Trending',
    'Coming Soon',
    'Free to Play',
    'Special Offers',
    'Award Winners',
    'Hidden Gems',
    'Early Access',
  ];

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

  static const List<String> specialInterests = [
    'Anime',
    'Asian Dramas',
    'Blockbuster Movies',
    'Bollywood Movies',
    'Documentaries',
    'Foreign',
    'Horror',
    'Reality TV',
    'Stand-Up Comedy',
    'Superhero',
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchRepository = SearchRepository();
    _scrollController = ScrollController();
    
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _lastQuery) {
        setState(() {
          _lastQuery = query;
          _currentPage = 0;
          _searchResults = [];
          _hasMore = true;
        });
        _searchGames();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.9; // %90'ına geldiğinde yeni sayfa yükle
    
    if (currentScroll >= threshold && !_isLoading && _hasMore) {
      print('Scroll threshold reached. Current page: $_currentPage'); // Debug için
      setState(() {
        _currentPage++;
      });
      _searchGames();
    }
  }

  Future<void> _searchGames() async {
    if (_lastQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Fetching results for page: $_currentPage');
      final response = await _searchRepository.searchGames(
        _lastQuery,
        _currentPage,
        _pageSize,
      );

      setState(() {
        print('Search Results: ${response.content.length}');
        
        _searchResults.addAll(response.content);
        _hasMore = !response.last;
        _isLoading = false;
      });
    } catch (e) {
      print('Search Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => _buildChip(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RelatedGamesPage(categoryTitle: label),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'No results found.',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _searchResults.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return _buildGameItem(_searchResults[index]);
      },
    );
  }

  Widget _buildGameItem(SearchGame game) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Container(
          width: 60,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: game.imageUrl != null && game.imageUrl!.isNotEmpty
                ? Image.network(
                    game.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.videogame_asset_rounded,
                      color: AppTheme.textSecondary,
                      size: 30,
                    ),
                  )
                : const Icon(
                    Icons.videogame_asset_rounded,
                    color: AppTheme.textSecondary,
                    size: 30,
                  ),
          ),
        ),
        title: Text(
          game.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.accentColor,
          size: 18,
        ),
        onTap: () {
          if (game.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameDetailPage(id: game.id!),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ],
      ),
      body: _searchResults.isEmpty && _lastQuery.isEmpty
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Popular', popularCategories),
                  const SizedBox(height: 16),
                  _buildSection('Genre', genres),
                  const SizedBox(height: 16),
                  _buildSection('Themes', themes),
                ],
              ),
            )
          : _buildSearchResults(),
    );
  }
}
