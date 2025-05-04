import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';
import 'package:ludicapp/services/model/response/user_game_rating_with_user.dart';
import 'package:ludicapp/services/repository/rating_repository.dart';
import 'package:ludicapp/services/model/request/rating_filter_request.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/core/widgets/review_modal.dart';
import 'package:ludicapp/core/enums/play_status.dart';
import 'package:ludicapp/core/enums/completion_status.dart';

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
      
      print('Received ${ratings.content.length} ratings from API');
      
      // Backend API'den gelen yanıtı debug et
      for (int i = 0; i < ratings.content.length; i++) {
        print('Rating $i: userId=${ratings.content[i].userId}, username=${ratings.content[i].username}, rating=${ratings.content[i].rating}, comment=${ratings.content[i].comment}');
      }

      if (mounted) {
        setState(() {
          _ratings = ratings.content;
          print('Total ratings after update: ${_ratings.length}');
          
          _isLoading = false;
          _currentPage = 1;
          _hasMoreData = ratings.content.length == _pageSize;
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
      
      print('Received ${moreRatings.content.length} more ratings from API');

      if (mounted) {
        setState(() {
          _ratings.addAll(moreRatings.content);
          print('Total ratings after adding more: ${_ratings.length}');
          
          _isLoading = false;
          _currentPage++;
          _hasMoreData = moreRatings.content.length == _pageSize;
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      rating.lastUpdatedDate != null ? _formatDate(rating.lastUpdatedDate!) : 'Unknown date',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (rating.rating != null)
                  Row(
                    children: List.generate(5, (starIndex) {
                      // Display 1-10 rating as 1-5 stars (simple mapping)
                      double starValue = (rating.rating! / 2.0);
                      IconData iconData = starIndex < starValue
                          ? (starIndex + 0.5 == starValue ? Icons.star_half : Icons.star)
                          : Icons.star_border;
                      return Icon(
                        iconData,
                        color: Colors.amber[400],
                        size: 18,
                      );
                    }),
                  ),
                if (rating.rating == null)
                   Text(
                      'Not Rated',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                if (rating.comment != null && rating.comment!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      rating.comment!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                // Add playtime, play status and completion status info
                if (rating.playStatus != null && rating.playStatus != PlayStatus.notSet ||
                    rating.completionStatus != null && rating.completionStatus != CompletionStatus.notSelected ||
                    rating.playtimeInMinutes != null && rating.playtimeInMinutes! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8, // Space between items
                      runSpacing: 4, // Space between lines
                      children: [
                        if (rating.playStatus != null && rating.playStatus != PlayStatus.notSet)
                          _buildInfoChip(
                            _getPlayStatusIcon(rating.playStatus!),
                            _getPlayStatusText(rating.playStatus!),
                            Colors.blue[300]!,
                          ),
                        if (rating.completionStatus != null && rating.completionStatus != CompletionStatus.notSelected)
                          _buildInfoChip(
                            _getCompletionStatusIcon(rating.completionStatus!),
                            _getCompletionStatusText(rating.completionStatus!),
                            Colors.green[300]!,
                          ),
                        if (rating.playtimeInMinutes != null && rating.playtimeInMinutes! > 0)
                          _buildInfoChip(
                            Icons.timer_outlined,
                            _formatPlaytime(rating.playtimeInMinutes!),
                            Colors.orange[300]!,
                          ),
                      ],
                    ),
                  ),
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: CircularProgressIndicator(color: Colors.white70),
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
            if (reviewToEdit.rating != null && reviewToEdit.rating! > 0) {
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
                   lastUpdatedDate: _ratings[index].lastUpdatedDate
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

  // Builds the card for the current user's rating/review if provided
  Widget _buildUserRatingCard() {
    if (widget.userRating == null) return const SizedBox.shrink();
    
    // Create a UserGameRatingWithUser object for consistent rendering
    final UserGameRatingWithUser userRatingData = UserGameRatingWithUser(
      id: 0,
      userId: _currentUserId ?? 0,
      username: 'You', // Placeholder
      gameId: widget.gameId,
      rating: widget.userRating?.rating,
      comment: widget.userRating?.comment,
      // Use lastUpdatedDate from userRating if available
      lastUpdatedDate: widget.userRating?.lastUpdatedDate, 
      // Set other fields as needed or null
      playStatus: widget.userRating?.playStatus,
      completionStatus: widget.userRating?.completionStatus,
      playtimeInMinutes: widget.userRating?.playtimeInMinutes,
      profilePhotoType: null, // Set appropriately if you have user profile data
      profilePhotoUrl: null, // Set appropriately
    );

    return Card(
      color: Colors.blueGrey[800], // Highlight user's card
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
                const Text(
                  'Your Review',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Use lastUpdatedDate and handle null
                Text(
                  userRatingData.lastUpdatedDate != null ? _formatDate(userRatingData.lastUpdatedDate!) : 'Not saved yet',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
             if (userRatingData.rating != null)
              Row(
                children: List.generate(5, (starIndex) {
                  // Display 1-10 rating as 1-5 stars (simple mapping)
                  double starValue = (userRatingData.rating! / 2.0);
                  IconData iconData = starIndex < starValue
                      ? (starIndex + 0.5 == starValue ? Icons.star_half : Icons.star)
                      : Icons.star_border;
                  return Icon(
                    iconData,
                    color: Colors.amber[400],
                    size: 18,
                  );
                }),
              ),
            if (userRatingData.rating == null)
              Text(
                'Not Rated',
                 style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                 ),
              ),
            if (userRatingData.comment != null && userRatingData.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  userRatingData.comment!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
             if (userRatingData.comment == null || userRatingData.comment!.isEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 12),
                 child: Text(
                   'No review written yet.',
                   style: TextStyle(
                     color: Colors.grey[600],
                     fontSize: 14,
                     fontStyle: FontStyle.italic,
                   ),
                 ),
               ),
            // Add playtime, play status and completion status info
            if (userRatingData.playStatus != null && userRatingData.playStatus != PlayStatus.notSet ||
                userRatingData.completionStatus != null && userRatingData.completionStatus != CompletionStatus.notSelected ||
                userRatingData.playtimeInMinutes != null && userRatingData.playtimeInMinutes! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8, // Space between items
                  runSpacing: 4, // Space between lines
                  children: [
                    if (userRatingData.playStatus != null && userRatingData.playStatus != PlayStatus.notSet)
                      _buildInfoChip(
                        _getPlayStatusIcon(userRatingData.playStatus!),
                        _getPlayStatusText(userRatingData.playStatus!),
                        Colors.blue[300]!,
                      ),
                    if (userRatingData.completionStatus != null && userRatingData.completionStatus != CompletionStatus.notSelected)
                      _buildInfoChip(
                        _getCompletionStatusIcon(userRatingData.completionStatus!),
                        _getCompletionStatusText(userRatingData.completionStatus!),
                        Colors.green[300]!,
                      ),
                    if (userRatingData.playtimeInMinutes != null && userRatingData.playtimeInMinutes! > 0)
                      _buildInfoChip(
                        Icons.timer_outlined,
                        _formatPlaytime(userRatingData.playtimeInMinutes!),
                        Colors.orange[300]!,
                      ),
                  ],
                ),
              ),

            // Edit button for user's review
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.white70),
                onPressed: () {
                  // Add null check for rating before comparison
                  if (userRatingData.rating != null && userRatingData.rating! > 0) {
                    ReviewModal.show(
                      context,
                      gameName: widget.gameName,
                      coverUrl: widget.coverUrl ?? '',
                      initialReview: userRatingData.comment,
                      onReviewSubmitted: (newComment) {
                         // TODO: Implement comment update logic
                        print('User review update requested: $newComment');
                        // Potentially call repository.updateRatingEntry here
                        // Then refresh the list: _loadInitialRatings()
                      },
                    );
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('You need to rate the game before adding a review.'))
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  IconData _getPlayStatusIcon(PlayStatus status) {
    switch (status) {
      case PlayStatus.notSet: return Icons.help_outline;
      case PlayStatus.playing: return Icons.gamepad;
      case PlayStatus.completed: return Icons.check_circle_outline;
      case PlayStatus.dropped: return Icons.cancel_outlined;
      case PlayStatus.onHold: return Icons.pause_circle_outline;
      case PlayStatus.backlog: return Icons.pending_outlined;
      case PlayStatus.skipped: return Icons.skip_next;
    }
  }

  String _getPlayStatusText(PlayStatus status) {
    switch (status) {
      case PlayStatus.notSet: return "Not Started";
      case PlayStatus.playing: return "Currently Playing";
      case PlayStatus.completed: return "Completed";
      case PlayStatus.dropped: return "Dropped";
      case PlayStatus.onHold: return "On Hold";
      case PlayStatus.backlog: return "In Backlog";
      case PlayStatus.skipped: return "Skipped";
    }
  }

  IconData _getCompletionStatusIcon(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.notSelected: return Icons.help_outline;
      case CompletionStatus.mainStory: return Icons.book_outlined;
      case CompletionStatus.mainStoryPlusExtras: return Icons.extension_outlined;
      case CompletionStatus.hundredPercent: return Icons.workspace_premium_outlined;
    }
  }

  String _getCompletionStatusText(CompletionStatus status) {
    switch (status) {
      case CompletionStatus.notSelected: return "Not Selected";
      case CompletionStatus.mainStory: return "Main Story";
      case CompletionStatus.mainStoryPlusExtras: return "Main Story + Extras";
      case CompletionStatus.hundredPercent: return "100% Completion";
    }
  }

  String _formatPlaytime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      if (mins > 0) {
        return "$hours hr $mins min";
      } else {
        return "$hours hr";
      }
    } else {
      return "$mins min";
    }
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
} 