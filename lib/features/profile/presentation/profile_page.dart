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
import 'dart:math';
import 'settings_page.dart';
import 'library_detail_page.dart';
import 'user_ratings_page.dart';
import 'all_libraries_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/core/enums/library_type.dart';
import 'package:ludicapp/services/model/response/paged_response.dart';
import 'package:ludicapp/services/repository/library_repository.dart';

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

class _ProfilePageState extends State<ProfilePage> {
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
  }

  @override
  void dispose() {
    _followedScrollController.dispose();
    super.dispose();
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
          _profileData = updatedProfile;
          SplashScreen.profileData = updatedProfile;
          SplashScreen.librarySummaries = updatedLibrarySummaries;
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
    try {
      setState(() => _isFollowing = !_isFollowing);
      // TODO: Implement follow/unfollow API call
      await _userRepository.refreshCurrentUserProfile(); // Refresh current user's following count
    } catch (e) {
      setState(() => _isFollowing = !_isFollowing); // Revert on error
      print('Error toggling follow: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bottom navigation'dan geliyorsa direkt SplashScreen verilerini kullan
    if (widget.isBottomNavigation) {
      _profileData = SplashScreen.profileData;
      return _buildProfileContent();
    }

    // Kendi profilimiz için SplashScreen verilerini kullan
    if (_isCurrentUser) {
      _profileData = SplashScreen.profileData;
      return _buildProfileContent();
    }

    // Diğer durumlar için loading ve error kontrolü
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Başka kullanıcının profili için data kontrolü
    if (!widget.isBottomNavigation && _profileData == null) {
      print(widget.isBottomNavigation);
      return const Scaffold(
        body: Center(child: Text('Error loading profile')),
      );
    }

    return _buildProfileContent();
  }

  Widget _buildProfileContent() {
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
                    _profileData?.username ?? '',
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
                        username: _profileData?.username ?? 'Guest User',
                        level: _profileData?.level.toInt() ?? 0,
                        progress: (_profileData?.level ?? 0) % 1,
                        followingCount: _profileData?.followingCount ?? 0,
                        followersCount: _profileData?.followerCount ?? 0,
                        onSettingsPressed: null,
                        onFollowingPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FollowingPage()),
                          );
                        },
                        onFollowersPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FollowersPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  if (_isCurrentUser) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        ),
                        icon: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        label: Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
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
                  _buildSectionHeader(
                    context,
                    _isCurrentUser ? 'My Library' : '${_profileData?.username ?? 'User'}\'s Library',
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllLibrariesPage(
                            username: _profileData?.username ?? 'User',
                            userId: _isCurrentUser ? null : widget.userId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildGameLibrary(context),
                  const SizedBox(height: 24),

                  // Followed Libraries Section should be right after user's library
                  _buildFollowedLibrariesSection(context),
                  
                  // Recent Activity Section comes after Followed Libraries
                  _buildRatedLibrarySection(context, _profileData?.librarySummaries ?? []),

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
    final librarySummaries = _isCurrentUser 
      ? (SplashScreen.librarySummaries ?? [])
      : (_profileData?.librarySummaries ?? []);
    
    if (librarySummaries.isEmpty) {
      return Center(
        child: Text(
          'No libraries found',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      );
    }

    return Column(
      children: [
        // Horizontal scrollable library list (Spotify style)
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: librarySummaries.length,
            itemBuilder: (context, index) {
              final summary = librarySummaries[index];
              
              // Kullanıcı kendi profili dışında bir profil görüntülüyorsa ve kütüphane takip edilebilir bir türdeyse
              // örneğin, CUSTOM tipindeki kütüphaneleri takip edebilir
              final bool isFollowableLibrary = !_isCurrentUser && widget.fromSearch && summary.libraryType == LibraryType.CUSTOM;
              
              return _buildSpotifyStyleLibraryCard(
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

  Widget _buildSpotifyStyleLibraryCard(
    BuildContext context, {
    required LibrarySummaryResponse librarySummary,
    required String imagePath,
    bool isFollowable = false,
  }) {
    final String title = librarySummary.displayName;
    final String count = librarySummary.gameCount.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryDetailPage(
              librarySummary: librarySummary,
              userId: widget.userId,
              isFollowable: isFollowable,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        height: 212, // Fixed height to prevent overflow
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image - fixed height
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: imagePath.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 160,
                      placeholder: (context, url) => Container(color: Colors.grey[800]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Icon(
                            _getLibraryIcon(title),
                            color: Colors.white.withOpacity(0.9),
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 160,
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
                          size: 40,
                        ),
                      ),
                    ),
              ),
            ),
            
            // Title and count - limited space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleMedium?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count Games',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRatedLibrarySection(BuildContext context, List<LibrarySummaryResponse> libraries) {
    // Find the rated library if it exists
    final ratedLibraryList = libraries.where((lib) => lib.libraryType == LibraryType.RATED).toList();
    
    // Return an empty state with a message instead of completely hiding the section
    if (ratedLibraryList.isEmpty || (_isCurrentUser && ratedLibraryList.first.gameCount == 0)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Recent Activity',
            onSeeAll: null, // No See All button for empty state
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Center(
              child: Text(
                _isCurrentUser 
                  ? 'You don\'t have any recent activity yet.' 
                  : '${_profileData?.username ?? "This user"} doesn\'t have any recent activity yet.',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }
    
    final ratedLibrary = ratedLibraryList.first;
    return _buildRatedGamesSection(context, ratedLibrary);
  }

  Widget _buildRatedGamesSection(BuildContext context, LibrarySummaryResponse ratedLibrary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context, 
          'Recent Activity',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserRatingsPage(
                  userId: _isCurrentUser ? null : widget.userId,
                  username: _profileData?.username ?? 'User',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Content of rated games section
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: min(ratedLibrary.gameCount, 10), // Limit to 10 or available games
            itemBuilder: (context, index) {
              // Placeholder for actual game items
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Game ${index + 1}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
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

  // --- Section for Followed Libraries ---
  Widget _buildFollowedLibrariesSection(BuildContext context) {
    final String sectionTitle = _isCurrentUser 
        ? 'Libraries You Follow' 
        : '${_profileData?.username ?? "User"}\'s Followed Libraries'; // Use username if available

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          sectionTitle,
          onSeeAll: () {
            final String? targetUserIdString = _isCurrentUser ? null : widget.userId;
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => AllLibrariesPage(
                  username: _profileData?.username ?? (_isCurrentUser ? 'Your' : 'User'),
                  userId: targetUserIdString,
                  fetchFollowedLibraries: true,
                )
              )
            );
            print('See All Followed Libraries tapped for user: $targetUserIdString');
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
        height: 220, // Maintain consistent height
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state (show error only if the list is empty)
    if (_errorFollowed != null && _followedLibraries.isEmpty) {
      return SizedBox(
        height: 220, // Maintain consistent height
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
        height: 220, // Maintain consistent height
        child: Center(
          child: Text(
            _isCurrentUser ? 'You are not following any libraries yet.' : 'This user isn\'t following any libraries yet.',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If we have libraries, show the list
    return SizedBox(
      height: 220, // Same height as user's own library section
      child: ListView.builder(
        controller: _followedScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // Add 1 for loader if loading more
        itemCount: _followedLibraries.length + (_isLoadingFollowed && _hasMoreFollowed ? 1 : 0),
        itemBuilder: (context, index) {
          // Loader at the end
          if (index == _followedLibraries.length) {
            return Container(
              width: 160, // Match card width
              height: 212,
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
          
          return _buildSpotifyStyleLibraryCard(
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
}
