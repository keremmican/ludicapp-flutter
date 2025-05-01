import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/library_category_card.dart';
import 'package:ludicapp/features/profile/presentation/widgets/followers_page.dart';
import 'package:ludicapp/features/profile/presentation/widgets/following_page.dart';
import 'package:ludicapp/features/profile/presentation/widgets/profile_header.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'package:ludicapp/services/repository/user_repository.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/models/profile_response.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';
import 'package:ludicapp/core/enums/display_mode.dart';
import 'dart:math';
import 'settings_page.dart';
import 'library_detail_page.dart';
import 'user_ratings_page.dart';
import 'all_libraries_page.dart';
import 'edit_profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/core/enums/library_type.dart';
import 'package:ludicapp/services/model/response/paged_response.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'package:ludicapp/features/profile/presentation/widgets/user_activities_section.dart';
import 'package:ludicapp/models/user_activity.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  final bool fromSearch;
  final bool isBottomNavigation;

  const ProfilePage({
    Key? key, 
    this.userId,
    this.fromSearch = false,
    this.isBottomNavigation = false,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final UserRepository _userRepository = UserRepository();
  final TokenService _tokenService = TokenService();
  final LibraryRepository _libraryRepository = LibraryRepository();
  ProfileResponse? _profileData;
  bool _isCurrentUser = false;
  bool _isLoading = false;
  bool _isFollowing = false;
  int? _currentUserId; // Kullanıcının kendi ID'si

  // State for Followed Libraries
  List<LibrarySummaryResponse> _followedLibraries = [];
  bool _isLoadingFollowed = false;
  bool _hasMoreFollowed = true;
  int _currentPageFollowed = 0;
  String? _errorFollowed;
  ScrollController _followedScrollController = ScrollController(); // For potential pagination

  static const List<String> mockImages = [
    'lib/assets/images/mock_games/game1.jpg',
    'lib/assets/images/mock_games/game2.jpg',
    'lib/assets/images/mock_games/game3.jpg',
    'lib/assets/images/mock_games/game4.jpg',
    'lib/assets/images/mock_games/game5.jpg',
    'lib/assets/images/mock_games/game6.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _followedScrollController.addListener(_onFollowedScroll); // Add listener if pagination needed
    // Register the observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    _followedScrollController.dispose();
    super.dispose();
  }

  // Listen to app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when the app resumes (page becomes visible)
    if (state == AppLifecycleState.resumed) {
      print("ProfilePage resumed. Refreshing data...");
      _refreshProfileDataInBackground();
      _loadFollowedLibraries(loadMore: false);
    }
  }

  // Add this method to refresh data when navigating back to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only refresh if we're not in the initial loading state
    if (!_isLoading && mounted) {
      print("ProfilePage dependencies changed. Refreshing data...");
      
      // Important: Force a refresh whenever dependencies change
      // This ensures data is refreshed when navigating back to this screen
      _refreshProfileDataInBackground();
      _loadFollowedLibraries(loadMore: false);
    }
  }

  // Listener for followed libraries pagination (optional)
  void _onFollowedScroll() {
    // Implement pagination logic if showing many followed libraries
    // Similar to other pagination implementations
  }

  Future<void> _initializeProfile() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = await _tokenService.getUserId();
      _isCurrentUser = widget.userId == null || widget.userId == currentUserId.toString();
      _currentUserId = currentUserId; // Kullanıcı ID'sini kaydet

      if (_isCurrentUser) {
        // Use SplashScreen data for initial display
        _profileData = SplashScreen.profileData;
        // Refresh current user data in background
        _refreshCurrentUserData(); 
      } else {
        // Load other user's profile data
        await _loadOtherUserProfile();
      }
      
      // Always load followed libraries after determining the target user
      await _loadFollowedLibraries(); 

    } catch (e) {
      print('Error initializing profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      // Ensure initial loading indicator is turned off if not already done
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshCurrentUserData() async {
    try {
      // Profil verilerini güncelle
      final updatedProfile = await _userRepository.fetchUserProfile();
      
      // Library verilerini güncelle
      final userId = await _tokenService.getUserId();
      final updatedLibrarySummaries = await _libraryRepository.getAllLibrarySummaries(
        userId: userId.toString(),
      );

      if (mounted) {
        setState(() {
          // Ensure librarySummaries is assigned to updatedProfile
          if (updatedProfile != null) {
            updatedProfile.librarySummaries = updatedLibrarySummaries ?? [];
          }
          
          _profileData = updatedProfile;
          // Also update SplashScreen data for completeness, but not rely on it for UI
          SplashScreen.profileData = updatedProfile;
          SplashScreen.librarySummaries = updatedLibrarySummaries;
          
          // Log to confirm update happened
          print("ProfilePage: Refreshed user data - libraries count: ${updatedLibrarySummaries?.length ?? 0}");
        });
      }
    } catch (e) {
      print('Error refreshing current user data: $e');
    }
  }

  Future<void> _loadOtherUserProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _userRepository.fetchUserProfile(userId: widget.userId);
      final librarySummaries = await _libraryRepository.getAllLibrarySummaries(
        userId: widget.userId,
      );
      
      response.librarySummaries = librarySummaries;
      
      if (mounted) {
        setState(() {
          _profileData = response;
          _isLoading = false;
          _isFollowing = response.isFollowing ?? false;
        });
      }
    } catch (e) {
      print('Error loading other user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method to load followed libraries
  Future<void> _loadFollowedLibraries({bool loadMore = false}) async {
    if (_isLoadingFollowed) return; 
    
    // Determine the target user ID
    final int? targetUserId;
    if (_isCurrentUser) {
      targetUserId = await _tokenService.getUserId();
    } else {
      targetUserId = int.tryParse(widget.userId ?? '');
    }

    if (targetUserId == null) {
      print('Could not determine target user ID for followed libraries.');
      if (mounted) setState(() { _errorFollowed = 'Could not find user.'; });
      return; // Cannot proceed without a user ID
    }

    setState(() {
      _isLoadingFollowed = true;
      if (!loadMore) {
        _errorFollowed = null;
        _currentPageFollowed = 0;
        _followedLibraries = [];
        _hasMoreFollowed = true;
      }
    });

    try {
      final response = await _libraryRepository.getFollowedLibrariesByUser(
        targetUserId,
        page: _currentPageFollowed,
        size: 10, // Load fewer for profile preview
      );

      if (response != null && mounted) {
        setState(() {
          _followedLibraries.addAll(response.content);
          _hasMoreFollowed = !response.last;
          if (_hasMoreFollowed) {
            _currentPageFollowed++;
          }
        });
      } else if (response == null && mounted) {
        _hasMoreFollowed = false;
      }
    } catch (e) {
      print('Error loading followed libraries: $e');
      if (mounted && !loadMore) {
        setState(() {
          _errorFollowed = 'Failed to load followed libraries.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFollowed = false;
        });
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report User', style: TextStyle(color: Colors.white)),
              onTap: () {
                // TODO: Implement report functionality
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User', style: TextStyle(color: Colors.white)),
              onTap: () {
                // TODO: Implement block functionality
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) {
      print('Cannot follow/unfollow: User ID is missing.');
      return;
    }
    final int? targetUserId = int.tryParse(widget.userId!);
    if (targetUserId == null) {
      print('Cannot follow/unfollow: Invalid User ID format.');
      return;
    }

    final bool intendToFollow = !_isFollowing;
    // Optimistically update UI
    setState(() => _isFollowing = intendToFollow);

    try {
      bool success;
      if (intendToFollow) {
        success = await _userRepository.followUser(targetUserId);
      } else {
        success = await _userRepository.unfollowUser(targetUserId);
      }

      if (!success) {
        // Revert UI on failure
        if (mounted) {
          setState(() => _isFollowing = !intendToFollow);
        }
        print('API call to ${intendToFollow ? 'follow' : 'unfollow'} failed.');
        // Optionally show a snackbar or message to the user
      } else {
        // Refresh current user's profile to update counts
        // We only need to refresh if the action was successful and *we* are the current user
        // But refreshing the *other* user's profile might be needed if their follower count is displayed dynamically (which it is)
        // For simplicity, let's try refreshing the current user's data as it might update their following count
        // And potentially refresh the viewed profile's data if needed (though fetchUserProfile doesn't directly update follower count on the response object itself)
        
        // Refresh current user's data in the background (updates follower/following counts in cache)
        _userRepository.refreshCurrentUserProfile();
        
        // Also, re-fetch the viewed user's profile data to potentially get updated follower counts
        // This assumes the backend updates the followerCount immediately in the profile response.
        if (widget.userId != null && !_isCurrentUser) {
          final refreshedProfile = await _userRepository.fetchUserProfile(userId: widget.userId);
          if (mounted && refreshedProfile != null) {
            setState(() {
               _profileData = _profileData?.copyWith(
                 followerCount: refreshedProfile.followerCount,
                 profilePhotoUrl: refreshedProfile.profilePhotoUrl,
                 profilePhotoType: refreshedProfile.profilePhotoType,
               );
            });
          }
        }
        print('Successfully ${intendToFollow ? 'followed' : 'unfollowed'} user $targetUserId');
      }
    } catch (e) {
      // Revert UI on error
      if (mounted) {
        setState(() => _isFollowing = !intendToFollow);
      }
      print('Error toggling follow for user $targetUserId: $e');
      // Optionally show a snackbar or message to the user
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage())
    );
    
    if (result == 'updated') {
      print("ProfilePage: Received update signal from EditProfilePage");
      // Yeni profil verilerini yükle ve UI'ı güncelle
      await _refreshProfileDataInBackground();
      setState(() {
        // UI'ı yenilemeye zorla
        print("ProfilePage: Forcing UI update after profile edit");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the state (_profileData) consistently instead of SplashScreen data
    
    // Initial loading check
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // For bottom navigation (home), ensure we still have valid data
    if (widget.isBottomNavigation && _profileData == null) {
      // If we don't have profile data in state yet, initialize from SplashScreen
      // but only as a fallback
      _profileData = SplashScreen.profileData;
      
      // Then still trigger a refresh for next time
      Future.microtask(() {
        _refreshProfileDataInBackground();
        _loadFollowedLibraries(loadMore: false);
      });
    }
    
    // For current user, ensure we have valid data
    if (_isCurrentUser && _profileData == null) {
      // If we don't have profile data in state yet, initialize from SplashScreen
      // but only as a fallback
      _profileData = SplashScreen.profileData;
      
      // If SplashScreen data is also null, show loading or error
      if (_profileData == null) {
        print("ProfilePage: Current user profile data is null in both state and SplashScreen.");
        // Optionally return a loading indicator or error message here
        // For now, trigger refresh and let the build method handle null check later
        Future.microtask(() {
            _refreshProfileDataInBackground();
            _loadFollowedLibraries(loadMore: false);
        });
      } else {
          // Trigger refresh for next time even if using SplashScreen data
          Future.microtask(() {
              _refreshProfileDataInBackground();
              _loadFollowedLibraries(loadMore: false);
          });
      }
    }

    // Error state for other users
    if (!widget.isBottomNavigation && !_isCurrentUser && _profileData == null) {
      print(widget.isBottomNavigation);
      return const Scaffold(
        body: Center(child: Text('Error loading profile')),
      );
    }

    // Null check before building content
    if (_profileData == null) {
      // This handles cases where data is truly unavailable after checks
      print("ProfilePage: _profileData is null, showing loading/error.");
      return const Scaffold(
        body: Center(child: Text('Error loading profile data.')),
      );
    }

    // Always build with state data
    return _buildProfileContent();
  }

  Widget _buildProfileContent() {
    // Ensure profileData is not null here (already checked in build method)
    final profileData = _profileData!;

    return Scaffold(
      body: Column(
        children: [
          if (widget.fromSearch) ...[
            // Custom Navigation Bar
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[900]! 
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios, 
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    profileData.username,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_isCurrentUser)
                    IconButton(
                      icon: Icon(
                        Icons.more_vert, 
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: _showMoreOptions,
                    )
                  else
                    const SizedBox(width: 40), // For alignment
                ],
              ),
            ),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileHeader(
                        username: profileData.username,
                        level: profileData.level.toInt(),
                        progress: profileData.level % 1,
                        followingCount: profileData.followingCount,
                        followersCount: profileData.followerCount,
                        profilePhotoUrl: profileData.profilePhotoUrl,
                        profilePhotoType: profileData.profilePhotoType,
                        onSettingsPressed: _isCurrentUser ? () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        ).then((result) {
                          // Settings sayfasından dönüldüğünde, profil güncellenmişse yenile
                          if (result == 'updated') {
                            _refreshProfileDataInBackground();
                          }
                        }) : null,
                        onEditProfilePressed: _isCurrentUser ? _openEditProfile : null,
                        onFollowingPressed: () {
                          final int? targetUserId = _isCurrentUser 
                              ? _currentUserId 
                              : (widget.userId != null ? int.tryParse(widget.userId!) : null);
                          if (targetUserId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersPage(
                                  userId: targetUserId,
                                  username: profileData.username, 
                                  initialMode: DisplayMode.following,
                                ),
                              ),
                            );
                          } else {
                            print('Could not determine user ID for following page.');
                          }
                        },
                        onFollowersPressed: () {
                          final int? targetUserId = _isCurrentUser 
                              ? _currentUserId 
                              : (widget.userId != null ? int.tryParse(widget.userId!) : null);
                          if (targetUserId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersPage(
                                  userId: targetUserId,
                                  username: profileData.username, 
                                  initialMode: DisplayMode.followers,
                                ),
                              ),
                            );
                          } else {
                            print('Could not determine user ID for followers page.');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 70), // Adjusted spacing due to header changes
                  if (_isCurrentUser) ...[
                    const SizedBox(height: 0), // Remove extra space if button was here
                  ] else if (widget.fromSearch) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: _toggleFollow,
                        icon: Icon(
                          _isFollowing ? Icons.check : Icons.add,
                          color: _isFollowing 
                              ? Colors.white 
                              : Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        label: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isFollowing 
                                ? Colors.white 
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey[800] : Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // If neither current user nor fromSearch, add some space
                  if (!_isCurrentUser && !widget.fromSearch) const SizedBox(height: 24),

                  _buildSectionHeader(
                    context,
                    _isCurrentUser ? 'My Library' : "${profileData.username}'s Library",
                    onSeeAll: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllLibrariesPage(
                            username: profileData.username,
                            userId: _isCurrentUser ? null : widget.userId,
                          ),
                        ),
                      );
                      if (result == 'updated' && mounted) {
                         print('ProfilePage: Received update signal from AllLibrariesPage.');
                         _refreshProfileDataInBackground();
                         _loadFollowedLibraries(loadMore: false);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildGameLibrary(context),
                  const SizedBox(height: 24),

                  // Followed Libraries Section should be right after user's library
                  _buildFollowedLibrariesSection(context),
                  
                  // Recent Activity Section comes after Followed Libraries
                  UserActivitiesSection(
                    username: profileData.username,
                    userId: _isCurrentUser ? null : widget.userId,
                    isCurrentUser: _isCurrentUser,
                    activities: UserActivity.generateMockActivities(),
                  ),
                  
                  // Steam Profile Section (Remains last)
                  _buildSteamProfile(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 16),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameLibrary(BuildContext context) {
    // Use state variable _profileData here
    final librarySummaries = _profileData?.librarySummaries ?? [];
    
    if (librarySummaries.isEmpty) {
      return Center(
        child: Text(
          'No libraries found',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      );
    }

    // Create a mutable copy for sorting
    List<LibrarySummaryResponse> sortedSummaries = List.from(librarySummaries);

    // Safely parse and sort libraries by updatedAt in descending order (most recent first)
    sortedSummaries.sort((a, b) {
      DateTime? dateA = a.updatedAt != null ? DateTime.tryParse(a.updatedAt.toString()) : null;
      DateTime? dateB = b.updatedAt != null ? DateTime.tryParse(b.updatedAt.toString()) : null;

      // Handle null dates (put them at the end)
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // a comes after b
      if (dateB == null) return -1; // a comes before b

      // Compare valid dates (descending)
      return dateB.compareTo(dateA);
    });

    return Column(
      children: [
        // Horizontal scrollable library list
        SizedBox(
          height: 120, // Adjust height for new card design
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedSummaries.length,
            itemBuilder: (context, index) {
              final summary = sortedSummaries[index];
              
              // Kullanıcı kendi profili dışında bir profil görüntülüyorsa ve kütüphane takip edilebilir bir türdeyse
              // örneğin, CUSTOM tipindeki kütüphaneleri takip edebilir
              final bool isFollowableLibrary = !_isCurrentUser && widget.fromSearch && summary.libraryType == LibraryType.CUSTOM;
              
              return _buildLibraryCard(
                context,
                librarySummary: summary,
                imagePath: summary.coverUrl ?? mockImages[Random().nextInt(mockImages.length)],
                isFollowable: isFollowableLibrary,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryCard(
    BuildContext context, {
    required LibrarySummaryResponse librarySummary,
    required String imagePath,
    bool isFollowable = false,
  }) {
    final String title = librarySummary.displayName;
    final String count = librarySummary.gameCount.toString();

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryDetailPage(
              librarySummary: librarySummary,
              userId: widget.userId,
              isFollowable: isFollowable,
            ),
          ),
        );

        if (result == 'updated') {
          print('ProfilePage: Received update signal from LibraryDetailPage.');
          _refreshProfileDataInBackground();
          _loadFollowedLibraries(loadMore: false);
        } else if (result == 'deleted' && _isCurrentUser) {
          print('ProfilePage: Received delete signal for library ${librarySummary.id}');
          _refreshProfileDataInBackground();
        }
      },
      child: Container(
        width: 260, // Increased width for horizontal layout
        margin: const EdgeInsets.only(right: 12, bottom: 8, top: 8), // Add vertical margin
        child: Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias, // Clip the image corners
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Image Section
              SizedBox(
                width: 90, // Fixed width for image
                height: double.infinity, // Take full height of the card
                child: ClipRRect(
                  // No need for separate borderRadius here if using Card's clipBehavior
                  child: imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(color: Colors.grey[800]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[700],
                          child: Center(
                            child: Icon(
                              _getLibraryIcon(title),
                              color: Colors.white.withOpacity(0.7),
                              size: 30,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getLibraryGradient(title),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getLibraryIcon(title),
                            color: Colors.white.withOpacity(0.9),
                            size: 30,
                          ),
                        ),
                      ),
                ),
              ),

              // Text Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Center text vertically
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontSize: 15, // Slightly larger font
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2, // Allow two lines for title
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count Games',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFollowedLibrariesSection(BuildContext context) {
    // Use state variable _profileData here for username
    final String sectionTitle = _isCurrentUser 
        ? 'Libraries You Follow' 
        : '${_profileData?.username ?? "User"}\'s Followed Libraries'; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          sectionTitle,
          onSeeAll: () async {
            final String? targetUserIdString = _isCurrentUser ? null : widget.userId;
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => AllLibrariesPage(
                  // Use state variable _profileData here for username
                  username: _profileData?.username ?? (_isCurrentUser ? 'Your' : 'User'),
                  userId: targetUserIdString,
                  fetchFollowedLibraries: true,
                )
              )
            );
            print('See All Followed Libraries tapped for user: $targetUserIdString');
            if (result == 'updated' && mounted) {
                print('ProfilePage: Received update signal from AllLibrariesPage (Followed).');
                _loadFollowedLibraries(loadMore: false);
            }
          },
        ),
        const SizedBox(height: 16),
        _buildFollowedLibrariesContent(),
        const SizedBox(height: 24),
      ],
    );
  }

  // Helper widget to build the content of the followed libraries section
  Widget _buildFollowedLibrariesContent() {
    // Loading state (show loader only if the list is currently empty)
    if (_isLoadingFollowed && _followedLibraries.isEmpty) {
      return const SizedBox(
        height: 120, // Maintain consistent height with the new card design
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state (show error only if the list is empty)
    if (_errorFollowed != null && _followedLibraries.isEmpty) {
      return SizedBox(
        height: 120, // Maintain consistent height
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(_errorFollowed!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
          )
        ),
      );
    }

    // Empty state (show a message if loading is finished and list is empty)
    if (_followedLibraries.isEmpty && !_isLoadingFollowed) {
      return SizedBox(
        height: 120, // Maintain consistent height
        child: Center(
          child: Text(
            _isCurrentUser ? 'You are not following any libraries yet.' : 'This user isn\'t following any libraries yet.',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    List<LibrarySummaryResponse> sortedFollowedLibraries = List.from(_followedLibraries);

    // Safely parse and sort followed libraries by updatedAt in descending order (most recent first)
    sortedFollowedLibraries.sort((a, b) {
      DateTime? dateA = a.updatedAt != null ? DateTime.tryParse(a.updatedAt.toString()) : null;
      DateTime? dateB = b.updatedAt != null ? DateTime.tryParse(b.updatedAt.toString()) : null;

      // Handle null or invalid dates (put them at the end)
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // a comes after b (put nulls last)
      if (dateB == null) return -1; // a comes before b (put nulls last)

      // Compare valid dates (descending)
      return dateB.compareTo(dateA);
    });

    // If we have libraries, show the list
    return SizedBox(
      height: 120, // Adjust height for new card design
      child: ListView.builder(
        controller: _followedScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // Add 1 for loader if loading more
        itemCount: _followedLibraries.length + (_isLoadingFollowed && _hasMoreFollowed ? 1 : 0),
        itemBuilder: (context, index) {
          // Loader at the end
          if (index == _followedLibraries.length) {
            return Container( // Placeholder loader matches card dimensions
              width: 260,
              height: 100,
              margin: const EdgeInsets.only(right: 12, bottom: 8, top: 8),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          // Library card
          final summary = _followedLibraries[index];
          
          // Takip edilen kütüphaneler için hepsini takip edilebilir olarak işaretleyelim
          // Kullanıcının kendi kütüphanesi olmadığı sürece takip edilebilir olmalı
          // ownerUserId varsa ve current user ID ile eşleşiyorsa kullanıcının kendi kütüphanesidir
          final bool isOwnLibrary = summary.ownerUserId != null && 
                                   _currentUserId != null && 
                                   summary.ownerUserId == _currentUserId;
          final bool isFollowableLibrary = !isOwnLibrary; // Kendi kütüphanesi değilse takip edilebilir
          
          return _buildLibraryCard(
            context,
            librarySummary: summary,
            // Provide a fallback image path if needed
            imagePath: summary.coverUrl ?? mockImages[Random().nextInt(mockImages.length)],
            isFollowable: isFollowableLibrary, // Takip edilebilirlik parametresini ekleyelim
          );
        },
      ),
    );
  }

  // Helper function to refresh profile data without showing a loading indicator
  Future<void> _refreshProfileDataInBackground() async {
    print("Refreshing profile data in background...");
    try {
      if (_isCurrentUser) {
        await _refreshCurrentUserData();
      } else if (widget.userId != null) {
        final refreshedProfile = await _userRepository.fetchUserProfile(userId: widget.userId);
        final refreshedLibrarySummaries = await _libraryRepository.getAllLibrarySummaries(
          userId: widget.userId,
        );
        
        if (refreshedProfile != null) {
          refreshedProfile.librarySummaries = refreshedLibrarySummaries ?? [];
        }

        if (mounted && refreshedProfile != null) {
          setState(() {
            _profileData = refreshedProfile;
            _isFollowing = refreshedProfile.isFollowing ?? _isFollowing;
            
            print("ProfilePage: Background refresh completed - libraries count: ${refreshedLibrarySummaries?.length ?? 0}");
          });
        } else if (mounted) {
            print("ProfilePage: Background refresh failed or component unmounted.");
        }
      }
    } catch (e) {
      print('Error refreshing profile data in background: $e');
    }
  }

  IconData _getLibraryIcon(String title) {
      switch (title) {
        case 'Saved':
          return Icons.bookmark;
        case 'Hidden':
          return Icons.visibility_off;
        case 'Rated':
          return Icons.star;
        case 'Currently Playing':
          return Icons.sports_esports;
        default:
          return Icons.games;
      }
    }

  List<Color> _getLibraryGradient(String title) {
      switch (title) {
        case 'Saved':
          return [Color(0xFF6A3093), Color(0xFFA044FF)];
        case 'Hidden':
          return [Color(0xFF434343), Color(0xFF000000)];
        case 'Rated':
          return [Color(0xFFFF512F), Color(0xFFDD2476)];
        case 'Currently Playing':
          return [Color(0xFF1A2980), Color(0xFF26D0CE)];
        default:
          return [Color(0xFF4B79A1), Color(0xFF283E51)];
      }
  }

  Widget _buildSteamProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Steam Profile'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildSteamStat(
                  context: context,
                  icon: Icons.sports_esports,
                  label: 'Games Played',
                  value: '120',
                ),
                const SizedBox(height: 16),
                _buildSteamStat(
                  context: context,
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  value: '350',
                ),
                const SizedBox(height: 16),
                _buildSteamStat(
                  context: context,
                  icon: Icons.timer,
                  label: 'Hours Played',
                  value: '540',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamStat({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
