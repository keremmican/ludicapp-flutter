import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';
import 'package:ludicapp/services/model/response/user_game_rating_with_user.dart';
import 'package:ludicapp/services/repository/rating_repository.dart';
import 'package:ludicapp/services/model/request/rating_filter_request.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/core/widgets/review_modal.dart';

class AllReviewsPage extends StatefulWidget {
  final int gameId;
  final String gameName;
  final String? coverUrl;
  final UserGameRating? userRating; // Kullanıcının kendi yorumu

  const AllReviewsPage({
    Key? key,
    required this.gameId,
    required this.gameName,
    this.coverUrl,
    this.userRating,
  }) : super(key: key);

  @override
  _AllReviewsPageState createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  final RatingRepository _ratingRepository = RatingRepository();
  final TokenService _tokenService = TokenService();
  final ScrollController _scrollController = ScrollController();
  
  List<UserGameRatingWithUser> _ratings = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserIdAndInitialRatings();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreRatings();
    }
  }

  Future<void> _loadCurrentUserIdAndInitialRatings() async {
    await _loadCurrentUserId();
    if (_currentUserId != null && mounted) {
      await _loadInitialRatings();
    }
  }

  Future<void> _loadCurrentUserId() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      _currentUserId = await _tokenService.getUserId();
      print('AllReviewsPage - Current User ID: $_currentUserId');
    } catch (e) {
      print('Error loading current user ID: $e');
    } finally {
    }
  }

  Future<void> _loadInitialRatings() async {
    print('Loading initial ratings for game ${widget.gameId}');
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Sadece oyun ID'sine göre filtrele
      final filter = RatingFilterRequest(gameId: widget.gameId);
      
      print('Sending filter-with-user request for gameId: ${widget.gameId}');
      final ratings = await _ratingRepository.filterRatingsWithUser(
        filter: filter,
        page: 0,
        size: _pageSize,
      );
      
      print('Received ${ratings.length} ratings from API');
      
      // Backend API'den gelen yanıtı debug et
      for (int i = 0; i < ratings.length; i++) {
        print('Rating $i: userId=${ratings[i].userId}, username=${ratings[i].username}, rating=${ratings[i].rating}, comment=${ratings[i].comment}');
      }

      if (mounted) {
        setState(() {
          _ratings = ratings;
          print('Total ratings after update: ${_ratings.length}');
          
          _isLoading = false;
          _currentPage = 1;
          _hasMoreData = ratings.length == _pageSize;
        });
      }
    } catch (e) {
      print('Error loading initial ratings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreRatings() async {
    print('Loading more ratings, page: $_currentPage');
    
    if (_isLoading || !_hasMoreData) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Sadece oyun ID'sine göre filtrele
      final filter = RatingFilterRequest(gameId: widget.gameId);
      
      print('Sending filter-with-user request for more ratings, page: $_currentPage');
      final moreRatings = await _ratingRepository.filterRatingsWithUser(
        filter: filter,
        page: _currentPage,
        size: _pageSize,
      );
      
      print('Received ${moreRatings.length} more ratings from API');

      if (mounted) {
        setState(() {
          _ratings.addAll(moreRatings);
          print('Total ratings after adding more: ${_ratings.length}');
          
          _isLoading = false;
          _currentPage++;
          _hasMoreData = moreRatings.length == _pageSize;
        });
      }
    } catch (e) {
      print('Error loading more ratings: $e');
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Reviews for ${widget.gameName}'),
        elevation: 0,
      ),
      body: _ratings.isEmpty && !_isLoading
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
            Icons.rate_review_outlined,
            color: Colors.grey[600],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts!',
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _ratings.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _ratings.length) {
          return _buildLoadingIndicator();
        }
        
        final rating = _ratings[index];
        
        // Kullanıcının kendi yorumunu kontrol et
        final bool isCurrentUser = _currentUserId != null && rating.userId == _currentUserId;
        
        return Card(
          color: isCurrentUser ? Colors.blueGrey[800] : Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCurrentUser ? 'Your Review' : rating.username,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.blue[300] : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isCurrentUser)
                      IconButton(
                        icon: Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit your review',
                        onPressed: () => _editReview(rating),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildUserAvatar(rating),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber[400],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${rating.rating}",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                _formatDate(rating.ratingDate),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (rating.comment != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    rating.comment!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUserAvatar(UserGameRatingWithUser rating) {
    // Determine the image widget based on type and URL
    Widget imageContent;
    final photoType = ProfilePhotoType.fromString(rating.profilePhotoType);
    final double radius = 20; // Define radius for consistency

    // DEBUG: Log photo details
    print('AllReviews - User: ${rating.username} - URL: ${rating.profilePhotoUrl} - Type: ${rating.profilePhotoType}');

    if (photoType == ProfilePhotoType.CUSTOM && rating.profilePhotoUrl != null && rating.profilePhotoUrl!.isNotEmpty) {
      // Custom URL - Use CachedNetworkImageProvider
      imageContent = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[700], // Placeholder background
        backgroundImage: CachedNetworkImageProvider(rating.profilePhotoUrl!),
      );
    } else {
      // Default asset or fallback
      final String? assetPath = photoType.assetPath;
      if (assetPath != null) {
        // Use local asset
        imageContent = CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[700], // Background for asset
          backgroundImage: AssetImage(assetPath),
        );
      } else {
        // Fallback placeholder
        imageContent = CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[700],
          child: Icon(Icons.person, color: Colors.white, size: radius * 1.2), // Adjust icon size based on radius
        );
      }
    }
    return imageContent; // Return the determined widget
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editReview(UserGameRatingWithUser reviewToEdit) {
    if (_currentUserId == null || reviewToEdit.userId != _currentUserId) return;

    ReviewModal.show(
      context,
      gameName: widget.gameName,
      coverUrl: widget.coverUrl ?? '',
      initialReview: reviewToEdit.comment,
      onReviewSubmitted: (newComment) async {
        try {
          if (newComment != null && newComment.isNotEmpty) {
            await _ratingRepository.commentGame(widget.gameId, newComment);
            print('AllReviewsPage: Comment updated successfully');
          } else {
            if (reviewToEdit.rating > 0) {
              await _ratingRepository.deleteComment(widget.gameId);
              print('AllReviewsPage: Comment deleted successfully');
            } else {
               print('AllReviewsPage: Skipping comment deletion, no prior rating.');
            }
          }

          if (mounted) {
            setState(() {
              final index = _ratings.indexWhere((r) => r.id == reviewToEdit.id);
              if (index != -1) {
                _ratings[index] = UserGameRatingWithUser(
                   id: _ratings[index].id,
                   userId: _ratings[index].userId,
                   username: _ratings[index].username,
                   profilePhotoUrl: _ratings[index].profilePhotoUrl,
                   profilePhotoType: _ratings[index].profilePhotoType,
                   gameId: _ratings[index].gameId,
                   rating: _ratings[index].rating,
                   comment: newComment,
                   ratingDate: _ratings[index].ratingDate
                );
              }
            });
          }
        } catch (e) {
          print('Error updating/deleting comment: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving review: ${e.toString()}')),
            );
          }
        }
      },
    );
  }
} 