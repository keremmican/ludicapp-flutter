import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/search_game.dart';
import 'package:ludicapp/services/repository/search_repository.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/model/response/game_category.dart';
import 'package:ludicapp/services/category_service.dart';
import 'dart:async';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/features/profile/presentation/related_games_page.dart';
import 'package:ludicapp/core/models/game.dart';
import 'dart:convert';
import 'package:ludicapp/services/api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const int _pageSize = 20;

  late final TextEditingController _searchController;
  late final SearchRepository _searchRepository;
  late final CategoryService _categoryService;
  late final ScrollController _scrollController;
  late final ApiService _apiService;
  
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
    'Free to Play'
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchRepository = SearchRepository();
    _categoryService = CategoryService();
    _scrollController = ScrollController();
    _apiService = ApiService();
    
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    
    _ensureCategoriesLoaded();
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

  Future<void> _ensureCategoriesLoaded() async {
    if (!_categoryService.isInitialized) {
      try {
        await _categoryService.initialize();
        if (mounted) setState(() {});
      } catch (e) {
        print('Error loading categories: $e');
      }
    }
  }

  Widget _buildSection(String title, List<dynamic> items) {
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
            children: items.map((item) => _buildChip(
              item is GameCategory ? item.name : item as String
            )).toList(),
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
          color: AppTheme.surfaceDark,
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
                builder: (context) => GameDetailPage(
                  game: Game.fromGameSummary(game.toGameSummary()),
                  fromSearch: true,
                ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Expanded(
              child: Container(
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
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _lastQuery = '';
                                _currentPage = 0;
                                _hasMore = true;
                              });
                            },
                          )
                        : null,
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      body: _searchResults.isEmpty && _lastQuery.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Popular', popularCategories),
                  const SizedBox(height: 16),
                  _buildSection('Genre', _categoryService.genres),
                  const SizedBox(height: 16),
                  _buildSection('Themes', _categoryService.themes),
                  const SizedBox(height: 16),
                  _buildSection('Platforms', _categoryService.platforms.map((p) => p['name'] as String).toList()),
                ],
              ),
            )
          : _buildSearchResults(),
    );
  }
}
