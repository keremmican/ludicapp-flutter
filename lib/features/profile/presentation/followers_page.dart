import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/user_follower_response.dart';
import 'package:ludicapp/services/model/response/paged_response.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/services/repository/user_repository.dart'; // For follow/unfollow actions
import 'package:ludicapp/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/features/profile/presentation/profile_page.dart'; // To navigate to user profiles
import 'package:ludicapp/services/token_service.dart'; // Import TokenService

class FollowersPage extends StatefulWidget {
  final int libraryId;
  final String libraryName;

  const FollowersPage({
    Key? key,
    required this.libraryId,
    required this.libraryName,
  }) : super(key: key);

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final LibraryRepository _libraryRepository = LibraryRepository();
  final UserRepository _userRepository = UserRepository(); // For follow/unfollow
  final TokenService _tokenService = TokenService(); // Add TokenService instance
  final ScrollController _scrollController = ScrollController();

  List<UserFollowerResponse> _followers = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  String? _error;
  int? _currentUserId; // Add state for current user ID

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load current user ID first, then load followers
    _loadCurrentUserIdAndFollowers();
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
    final threshold = maxScroll * 0.9;

    if (currentScroll >= threshold && !_isLoadingMore && _hasMore && !_isInitialLoading) {
      _loadFollowers(loadMore: true);
    }
  }

  Future<void> _loadCurrentUserIdAndFollowers() async {
    await _loadCurrentUserId();
    // Only load followers if current user ID is successfully fetched
    if (mounted && _currentUserId != null) {
      _loadFollowers();
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      _currentUserId = await _tokenService.getUserId();
    } catch (e) {
      print("Error loading current user ID: $e");
      if (mounted) {
        setState(() {
          _error = "Could not verify user.";
          _isInitialLoading = false; // Stop initial loading indicator
        });
      }
    }
  }

  Future<void> _loadFollowers({bool loadMore = false}) async {
    if (_isLoading) return; // Prevent simultaneous loads

    setState(() {
      _isLoading = true;
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isInitialLoading = true;
        _error = null;
        _currentPage = 0; // Reset page for initial load
        _followers = []; // Clear previous results for initial load
        _hasMore = true; // Assume there's more initially
      }
    });

    try {
      final response = await _libraryRepository.getLibraryFollowers(
        widget.libraryId,
        page: _currentPage,
        size: _pageSize,
      );

      if (response != null && mounted) {
        setState(() {
          _followers.addAll(response.content);
          _hasMore = !response.last;
          if (_hasMore) {
            _currentPage++;
          }
        });
      } else if (response == null && mounted) {
        // Handle null response as potentially no more data or error
        _hasMore = false;
        if (!loadMore) {
           _error = 'Could not load followers.';
        }
      }
    } catch (e) {
      print('Error loading followers: $e');
      if (mounted) {
        setState(() {
          if (!loadMore) {
            _error = 'Failed to load followers. Please try again.';
          }
          _hasMore = false; // Stop pagination on error
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  // --- Follow/Unfollow Logic ---
  Future<void> _toggleFollow(UserFollowerResponse user) async {
     // Prevent action if already processing or userId is null
     if (user.isProcessing || user.userId == null) return;

     final bool intendToFollow = !user.isFollowing;

     setState(() {
        user.isProcessing = true; // Set processing flag
     });

     try {
        bool success = false;
        if (intendToFollow) {
           success = await _userRepository.followUser(user.userId!);
        } else {
           success = await _userRepository.unfollowUser(user.userId!);
        }

        if (success && mounted) {
           setState(() {
              user.isFollowing = intendToFollow;
           });
           // Optional: Show success SnackBar
           // ScaffoldMessenger.of(context).showSnackBar(
           //   SnackBar(content: Text(intendToFollow ? 'User followed' : 'User unfollowed')),
           // );
        } else if (mounted) {
            // Optional: Show error SnackBar
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(content: Text('Failed to ${intendToFollow ? 'follow' : 'unfollow'} user.')),
            // );
        }
     } catch (e) {
       print('Error toggling follow: $e');
       if (mounted) {
         // Optional: Show error SnackBar
         // ScaffoldMessenger.of(context).showSnackBar(
         //   SnackBar(content: Text('Error: ${e.toString()}')),
         // );
       }
     } finally {
        if (mounted) {
           setState(() {
              user.isProcessing = false; // Reset processing flag
           });
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text('Followers of ${widget.libraryName}'),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadFollowers(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No followers yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Build the list view
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: _followers.length + (_isLoadingMore ? 1 : 0), // Add space for loader
      itemBuilder: (context, index) {
        if (index == _followers.length) {
          // If it's the loader item
          return _buildLoadingIndicator();
        }

        final user = _followers[index];
        return _buildFollowerListItem(user);
      },
    );
  }

  Widget _buildFollowerListItem(UserFollowerResponse user) {
    // Check if the displayed user is the current user
    final bool isCurrentUser = user.userId == _currentUserId;

    return ListTile(
      leading: GestureDetector(
         onTap: () {
           if (user.userId != null) {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => ProfilePage(userId: user.userId.toString(), fromSearch: true),
               ),
             );
           }
         },
         child: CircleAvatar(
           radius: 24,
           backgroundColor: Colors.grey[700],
           backgroundImage: user.profilePhotoUrl != null
               ? CachedNetworkImageProvider(user.profilePhotoUrl!)
               : null,
           child: user.profilePhotoUrl == null
               ? const Icon(Icons.person, color: Colors.white)
               : null,
         ),
      ),
      title: GestureDetector(
         onTap: () {
           if (user.userId != null) {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => ProfilePage(userId: user.userId.toString(), fromSearch: true),
               ),
             );
           }
         },
         child: Text(
           user.username,
           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
         ),
      ),
      trailing: isCurrentUser || user.userId == null
        ? const SizedBox.shrink() // Hide button if it's the current user or ID is null
        : _buildFollowButton(user),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  // Helper to build the follow/unfollow button
  Widget _buildFollowButton(UserFollowerResponse user) {
     final bool isFollowing = user.isFollowing;
     final bool isProcessing = user.isProcessing;

     return ElevatedButton(
        onPressed: isProcessing ? null : () => _toggleFollow(user),
        style: ElevatedButton.styleFrom(
           backgroundColor: isFollowing ? Colors.grey[800] : Theme.of(context).colorScheme.primary,
           foregroundColor: isFollowing ? Colors.white70 : Theme.of(context).colorScheme.onPrimary,
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
           minimumSize: const Size(80, 32), // Ensure a consistent size
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(20.0),
           ),
        ),
        child: isProcessing
           ? const SizedBox(
               width: 16,
               height: 16,
               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
             )
           : Text(isFollowing ? 'Following' : 'Follow'),
     );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
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
} 