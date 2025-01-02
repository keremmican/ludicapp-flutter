import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/search_game.dart';
import 'package:ludicapp/services/repository/search_repository.dart';
import 'dart:async';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchRepository _searchRepository = SearchRepository();
  final ScrollController _scrollController = ScrollController();
  
  List<SearchGame> _searchResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;
  static const int _pageSize = 10;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
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
        if (response.content.isEmpty || response.last) {
          _hasMore = false;
        } else {
          _searchResults.addAll(response.content);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Search Games',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for games...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Start typing to search games...',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[800],
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
                    color: Colors.white54,
                    size: 30,
                  ),
                )
              : const Icon(
                  Icons.videogame_asset_rounded,
                  color: Colors.white54,
                  size: 30,
                ),
        ),
      ),
      title: Text(
        game.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
      onTap: () {
        if (game.id != null) {
          Navigator.pushNamed(
            context,
            '/game-detail',
            arguments: game.id,
          );
        }
      },
    );
  }
}
