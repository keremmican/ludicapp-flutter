import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/user_follower_response.dart';
import 'package:ludicapp/services/model/response/paged_response.dart';
import 'package:ludicapp/services/repository/user_repository.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/features/profile/presentation/profile_page.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/core/enums/display_mode.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'dart:math';

class FollowersPage extends StatefulWidget {
  final int userId;
  final String username; // Username of the profile being viewed
  final DisplayMode initialMode;

  const FollowersPage({
    Key? key,
    required this.userId,
    required this.username,
    this.initialMode = DisplayMode.followers,
  }) : super(key: key);

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final UserRepository _userRepository = UserRepository();
  final TokenService _tokenService = TokenService();
  final ScrollController _scrollController = ScrollController();

  List<UserFollowerResponse> _users = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  String? _error;
  int? _currentUserId; // Logged-in user's ID
  late DisplayMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _scrollController.addListener(_onScroll);
    _loadCurrentUserIdAndUsers();
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
      _loadUsers(loadMore: true);
    }
  }

  Future<void> _loadCurrentUserIdAndUsers() async {
    await _loadCurrentUserId();
    if (mounted && _currentUserId != null) {
      _loadUsers();
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
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadUsers({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isInitialLoading = true;
        _error = null;
        _currentPage = 0;
        _users = [];
        _hasMore = true;
      }
    });

    try {
      print('==== LOADING ${_currentMode == DisplayMode.followers ? "FOLLOWERS" : "FOLLOWING"} ====');
      print('User ID: ${widget.userId}, Page: $_currentPage, Size: $_pageSize');
      
      final Future<PagedResponse<UserFollowerResponse>> fetchFuture =
          _currentMode == DisplayMode.followers
              ? _userRepository.getFollowers(
                  widget.userId,
                  page: _currentPage,
                  size: _pageSize,
                )
              : _userRepository.getFollowing(
                  widget.userId,
                  page: _currentPage,
                  size: _pageSize,
                );

      final response = await fetchFuture;
      
      // Log the full response
      print('API Response Content: ${response.content.length} items');
      print('Has more: ${!response.last}');
      
      // Log details about each user in the response
      for (int i = 0; i < response.content.length; i++) {
        final user = response.content[i];
        print('User #$i: ID=${user.userId}, Username=${user.username}');
        print('  isFollowing=${user.isFollowing}, isProcessing=${user.isProcessing}');
        if (user.profilePhotoUrl != null) {
          print('  Has profile photo: ${user.profilePhotoUrl!.substring(0, min(30, user.profilePhotoUrl!.length))}...');
        }
        // Check if the current logged-in user is following this user
        if (user.userId == _currentUserId) {
          print('  NOTE: This is the currently logged-in user');
        }
      }

      if (mounted) {
        setState(() {
          _users.addAll(response.content);
          _hasMore = !response.last;
          if (_hasMore) {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      final errorMsg = _currentMode == DisplayMode.followers
          ? 'Failed to load followers.'
          : 'Failed to load following.';
      print('Error loading ${_currentMode.name}: $e');
      if (mounted) {
        setState(() {
          if (!loadMore) {
            _error = errorMsg;
          }
          _hasMore = false;
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

  Future<void> _toggleFollow(UserFollowerResponse user) async {
     if (user.isProcessing || user.userId == null) return;

     final bool intendToFollow = !user.isFollowing;

     setState(() {
        user.isProcessing = true;
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
           _userRepository.refreshCurrentUserProfile();
        } else if (mounted) {
          print('Follow/unfollow API call failed');
        }
     } catch (e) {
       print('Error toggling follow: $e');
     } finally {
        if (mounted) {
           setState(() {
              user.isProcessing = false;
           });
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _currentMode == DisplayMode.followers
        ? '${widget.username}\'s Followers'
        : '${widget.username}\'s Following';

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(title),
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
                onPressed: () => _loadUsers(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      final String emptyMessage = _currentMode == DisplayMode.followers
          ? '${widget.username} has no followers yet.'
          : '${widget.username} isn\'t following anyone yet.';
      final IconData emptyIcon = _currentMode == DisplayMode.followers
          ? Icons.people_outline
          : Icons.person_add_disabled_outlined;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: _users.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _users.length) {
          return _buildLoadingIndicator();
        }

        final user = _users[index];
        return _buildUserListItem(user);
      },
    );
  }

  Widget _buildUserListItem(UserFollowerResponse user) {
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
         child: _buildUserAvatar(user),
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
        ? const SizedBox.shrink()
        : _buildFollowButton(user),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  Widget _buildUserAvatar(UserFollowerResponse user) {
    if (user.profilePhotoType == ProfilePhotoType.CUSTOM && 
        user.profilePhotoUrl != null && 
        user.profilePhotoUrl!.isNotEmpty) {
      // CUSTOM tipindeki profil fotoğrafı - URL'den yükle
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[700],
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.profilePhotoUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[800]),
            errorWidget: (context, url, error) => _buildDefaultAvatarIcon(),
          ),
        ),
      );
    } else {
      // DEFAULT tipindeki profil fotoğrafı - Asset'ten yükle
      final String? assetPath = user.profilePhotoType.assetPath;
      
      if (assetPath != null) {
        return CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[700],
          child: ClipOval(
            child: Image.asset(
              assetPath,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading avatar asset: $error');
                return _buildDefaultAvatarIcon();
              },
            ),
          ),
        );
      } else {
        // Fallback - profil fotoğrafı yoksa veya yüklenemezse
        return CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[700],
          child: _buildDefaultAvatarIcon(),
        );
      }
    }
  }
  
  Widget _buildDefaultAvatarIcon() {
    return Icon(
      Icons.person,
      color: Colors.white.withOpacity(0.7),
      size: 30,
    );
  }

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
