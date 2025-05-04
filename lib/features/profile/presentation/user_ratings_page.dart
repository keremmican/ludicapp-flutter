import 'package:flutter/material.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/services/repository/rating_repository.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'package:ludicapp/core/models/game.dart';

class UserRatingsPage extends StatefulWidget {
  final String username;
  final String? userId;
  
  const UserRatingsPage({
    Key? key,
    required this.username,
    this.userId,
  }) : super(key: key);

  @override
  State<UserRatingsPage> createState() => _UserRatingsPageState();
}

class _UserRatingsPageState extends State<UserRatingsPage> {
  final ScrollController _scrollController = ScrollController();
  final RatingRepository _ratingRepository = RatingRepository();
  final GameRepository _gameRepository = GameRepository();
  
  List<UserRatingItem> _ratingItems = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  
  @override
  void initState() {
    super.initState();
    _loadRatings();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll * 0.9 && !_isLoading && _hasMore) {
      _currentPage++;
      _loadRatings();
    }
  }
  
  Future<void> _loadRatings() async {
    if (_isLoading && _currentPage > 0) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user ratings
      final ratings = await _ratingRepository.getAllRatings(
        page: _currentPage,
        size: _pageSize,
      );
      
      if (ratings.empty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }
      
      // Fetch game details for each rating
      final ratingItems = <UserRatingItem>[];
      for (final rating in ratings.content) {
        try {
          final game = await _gameRepository.fetchGameDetails(rating.gameId);
          ratingItems.add(UserRatingItem(
            gameId: rating.gameId,
            gameName: game.name,
            coverUrl: game.coverUrl,
            rating: rating.rating,
            date: rating.lastUpdatedDate,
            comment: rating.comment,
          ));
        } catch (e) {
          print('Error fetching game details for gameId ${rating.gameId}: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          if (_currentPage == 0) {
            _ratingItems = ratingItems;
          } else {
            _ratingItems.addAll(ratingItems);
          }
          _hasMore = ratings.content.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ratings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text('${widget.username}\'s Ratings'),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: _isLoading && _ratingItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _ratingItems.isEmpty
              ? _buildEmptyState()
              : _buildRatingsList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No ratings yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rate games to see them here',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _ratingItems.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _ratingItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          );
        }
        
        final item = _ratingItems[index];
        return _buildRatingItem(item);
      },
    );
  }
  
  Widget _buildRatingItem(UserRatingItem item) {
    return GestureDetector(
      onTap: () async {
        try {
          final gameSummary = await _gameRepository.fetchGameDetails(item.gameId);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameDetailPage(
                  game: Game.fromGameSummary(gameSummary),
                ),
              ),
            );
          }
        } catch (e) {
          print('Error navigating to game detail: $e');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Game cover
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 80,
                height: 120,
                child: item.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.videogame_asset,
                          color: Colors.white38,
                          size: 32,
                        ),
                      ),
              ),
            ),
            
            // Game info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating stars
                    Row(
                      children: [
                        if (item.rating != null && item.rating! > 0)
                        ...List.generate(
                          5,
                            (i) {
                               double starValue = (item.rating! / 2.0);
                               IconData iconData = i < starValue
                                ? (i + 0.5 == starValue ? Icons.star_half : Icons.star)
                                : Icons.star_border;
                                return Icon(
                                  iconData,
                                  color: Colors.amber,
                            size: 20,
                               );
                            }
                          )
                        else 
                          Text(
                            'Not Rated',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show rating number only if it exists
                        if (item.rating != null && item.rating! > 0)
                        Text(
                          item.rating.toString(),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Game name
                    Text(
                      item.gameName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Rating date (handle null)
                    Text(
                      item.date != null ? _formatDate(item.date!) : 'Date unknown',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    
                    if (item.comment != null && item.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      
                      // Comment
                      Text(
                        item.comment!,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

class UserRatingItem {
  final int gameId;
  final String gameName;
  final String? coverUrl;
  final int? rating;
  final DateTime? date;
  final String? comment;
  
  UserRatingItem({
    required this.gameId,
    required this.gameName,
    this.coverUrl,
    this.rating,
    this.date,
    this.comment,
  });
} 