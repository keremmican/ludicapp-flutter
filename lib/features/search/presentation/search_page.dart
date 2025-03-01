import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/search_game.dart';
import 'package:ludicapp/services/model/response/search_user.dart';
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
import 'package:ludicapp/features/profile/presentation/profile_page.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  static const int _pageSize = 20;

  late final TextEditingController _searchController;
  late final SearchRepository _searchRepository;
  late final CategoryService _categoryService;
  late final ScrollController _scrollController;
  late final ApiService _apiService;
  late final TabController _tabController;
  late final FocusNode _searchFocusNode;
  
  List<SearchGame> _searchGamesResults = [];
  List<SearchUser> _searchUsersResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;
  Timer? _debounce;
  String _lastQuery = '';
  bool _isSearchFocused = false;

  static const List<String> popularCategories = [
    'New Releases',
    'Top Rated',
    'Coming Soon',
  ];

  static const List<Map<String, dynamic>> staticPlatforms = [
    {'id': 14, 'name': 'Mac'},
    {'id': 167, 'name': 'PlayStation 5'},
    {'id': 6, 'name': 'PC (Microsoft Windows)'},
    {'id': 130, 'name': 'Nintendo Switch'},
    {'id': 169, 'name': 'Xbox Series X|S'},
    {'id': 34, 'name': 'Android'},
    {'id': 48, 'name': 'PlayStation 4'},
    {'id': 49, 'name': 'Xbox One'},
    {'id': 39, 'name': 'iOS'},
    {'id': 3, 'name': 'Linux'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchRepository = SearchRepository();
    _categoryService = CategoryService();
    _scrollController = ScrollController();
    _apiService = ApiService();
    _tabController = TabController(length: 2, vsync: this);
    _searchFocusNode = FocusNode();
    
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(_onTabChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    
    _ensureCategoriesLoaded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _onTabChanged() {
    if (_lastQuery.isNotEmpty) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _searchGamesResults = [];
        _searchUsersResults = [];
      });
      // Delay the search to prevent UI glitch during tab animation
      Future.microtask(() => _performSearch());
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _lastQuery) {
        setState(() {
          _lastQuery = query;
          _currentPage = 0;
          _searchGamesResults = [];
          _searchUsersResults = [];
          _hasMore = true;
        });
        _performSearch();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.9;
    
    if (currentScroll >= threshold && !_isLoading && _hasMore) {
      setState(() {
        _currentPage++;
      });
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    if (_lastQuery.isEmpty) {
      setState(() {
        _searchGamesResults = [];
        _searchUsersResults = [];
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
      if (_tabController.index == 0) {
        await _searchGames();
      } else {
        await _searchUsers();
      }
    } catch (e) {
      print('Search Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchGames() async {
    final response = await _searchRepository.searchGames(
      _lastQuery,
      _currentPage,
      _pageSize,
    );

    setState(() {
      _searchGamesResults.addAll(response.content);
      _hasMore = !response.last;
      _isLoading = false;
    });
  }

  Future<void> _searchUsers() async {
    final response = await _searchRepository.searchUsers(
      _lastQuery,
      _currentPage,
      _pageSize,
    );

    setState(() {
      _searchUsersResults.addAll(response.content);
      _hasMore = !response.last;
      _isLoading = false;
    });
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
            children: title == 'Platforms' 
              ? staticPlatforms.map((platform) => _buildChip(
                  platform['name'] as String,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RelatedGamesPage(
                        categoryTitle: platform['name'] as String,
                        platformId: platform['id'] as int,
                      ),
                    ),
                  ),
                )).toList()
              : items.map((item) => _buildChip(
                  item is GameCategory ? item.name : item as String,
                  () {
                    if (title == 'Genre' && item is GameCategory) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatedGamesPage(
                            categoryTitle: item.name,
                            genreId: item.id,
                          ),
                        ),
                      );
                    } else if (title == 'Themes' && item is GameCategory) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RelatedGamesPage(
                            categoryTitle: item.name,
                            themeId: item.id,
                          ),
                        ),
                      );
                    } else {
                      final popularityTypeEntry = HomeController.popularityTypeTitles.entries
                          .firstWhere((entry) => entry.value == (item is GameCategory ? item.name : item as String), 
                          orElse: () => const MapEntry(-1, ''));
                          
                      if (popularityTypeEntry.key != -1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RelatedGamesPage(
                              categoryTitle: item is GameCategory ? item.name : item as String,
                              popularityTypeId: popularityTypeEntry.key,
                            ),
                          ),
                        );
                      } else if (item is! GameCategory) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RelatedGamesPage(categoryTitle: item as String),
                          ),
                        );
                      }
                    }
                  },
                )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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

    if (_tabController.index == 0) {
      if (_searchGamesResults.isEmpty) {
        if (_lastQuery.isEmpty) {
          return _buildEmptySearchMessage('games');
        }
        if (!_isLoading) {
          return const Center(
            child: Text(
              'No games found.',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          );
        }
      }
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _searchGamesResults.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _searchGamesResults.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          return _buildGameItem(_searchGamesResults[index]);
        },
      );
    } else {
      if (_searchUsersResults.isEmpty) {
        if (_lastQuery.isEmpty) {
          return _buildEmptySearchMessage('users');
        }
        if (!_isLoading) {
          return const Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          );
        }
      }
      return ListView.builder(
        controller: _scrollController,
        itemCount: _searchUsersResults.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _searchUsersResults.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          return _buildUserItem(_searchUsersResults[index]);
        },
      );
    }
  }

  Widget _buildEmptySearchMessage(String type) {
    String message = _tabController.index == 0 
      ? 'Type something to search for games'
      : 'Type something to search for users';
      
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameItem(SearchGame game) {
    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Cover Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: game.imageUrl != null && game.imageUrl!.isNotEmpty
                          ? Image.network(
                              game.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[850],
                                  child: const Center(
                                    child: Icon(
                                      Icons.videogame_asset_rounded,
                                      color: Colors.white70,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[850],
                              child: const Center(
                                child: Icon(
                                  Icons.videogame_asset_rounded,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Game name overlay at bottom of image with darker background
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        game.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              blurRadius: 3.0,
                              color: Colors.black,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(SearchUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppTheme.primaryDark,
          child: _buildUserAvatar(user),
        ),
        title: Text(
          user.name,
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                userId: user.id,
                fromSearch: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserAvatar(SearchUser user) {
    if (user.imageUrl == null || user.imageUrl!.isEmpty) {
      return const Icon(
        Icons.person,
        color: AppTheme.textSecondary,
        size: 30,
      );
    }

    return ClipOval(
      child: Image.network(
        user.imageUrl!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person,
          color: AppTheme.textSecondary,
          size: 30,
        ),
      ),
    );
  }

  void _handleCancel() {
    if (_isSearchFocused || _searchController.text.isNotEmpty) {
      _searchFocusNode.unfocus();
      _searchController.clear();
      setState(() {
        _searchGamesResults = [];
        _searchUsersResults = [];
        _lastQuery = '';
        _currentPage = 0;
        _hasMore = true;
        _isSearchFocused = false;
      });
    } else {
      Navigator.pop(context);
    }
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
                  focusNode: _searchFocusNode,
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
                                _searchGamesResults = [];
                                _searchUsersResults = [];
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
              onPressed: _handleCancel,
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ),
          ],
        ),
        bottom: _isSearchFocused || _searchController.text.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[900]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Games'),
                      Tab(text: 'Users'),
                    ],
                    labelColor: AppTheme.accentColor,
                    unselectedLabelColor: Colors.grey[400],
                    indicatorColor: AppTheme.accentColor,
                    indicatorWeight: 3,
                  ),
                ),
              )
            : null,
      ),
      body: _isSearchFocused || _searchController.text.isNotEmpty
          ? Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSearchResults(),
                      _buildSearchResults(),
                    ],
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Popular', [
                    ...popularCategories,
                    ...HomeController.popularityTypeTitles.values,
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Genre', _categoryService.genres),
                  const SizedBox(height: 16),
                  _buildSection('Themes', _categoryService.themes),
                  const SizedBox(height: 16),
                  _buildSection('Platforms', staticPlatforms.map((p) => p['name'] as String).toList()),
                ],
              ),
            ),
    );
  }
}
