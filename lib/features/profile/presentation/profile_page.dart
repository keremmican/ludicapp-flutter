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
import 'related_games_page.dart';
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
  }

  void _initializeProfile() {
    if (widget.isBottomNavigation) {
      // Bottom navigation'dan geliyorsa direkt SplashScreen verilerini kullan
      setState(() {
        _profileData = SplashScreen.profileData;
        _isCurrentUser = true;
      });
      // Arkaplanda güncelle
      _refreshCurrentUserData();
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final currentUserId = await _tokenService.getUserId();
      _isCurrentUser = widget.userId == null || widget.userId == currentUserId.toString();

      if (_isCurrentUser) {
        setState(() {
          _profileData = SplashScreen.profileData;
        });
        // Arkaplanda güncelle
        _refreshCurrentUserData();
      } else {
        setState(() => _isLoading = true);
        await _loadOtherUserProfile();
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (!_isCurrentUser) {
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
                color: AppTheme.primaryDark,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[900]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _profileData?.username ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_isCurrentUser)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
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
                  const SizedBox(height: 80),
                  if (_isCurrentUser) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        ),
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.black,
                          size: 20,
                        ),
                        label: const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
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
                          color: _isFollowing ? Colors.grey[400] : Colors.black,
                          size: 20,
                        ),
                        label: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isFollowing ? Colors.grey[400] : Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey[800] : AppTheme.accentColor,
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
                    'My Library',
                    onSeeAll: () {
                      print('See all library items');
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildGameLibrary(context),
                  const SizedBox(height: 24),
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
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
      return const Center(
        child: Text(
          'No libraries found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: librarySummaries.length,
      itemBuilder: (context, index) {
        final summary = librarySummaries[index];
        return _buildCategoryCard(
          context,
          title: summary.displayName,
          imagePath: summary.coverUrl ?? mockImages[Random().nextInt(mockImages.length)],
          count: summary.gameCount.toString(),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RelatedGamesPage(
                      categoryTitle: summary.displayName,
                      libraryId: summary.id,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String imagePath,
    required String count,
    required VoidCallback onTap,
  }) {
    IconData getLibraryIcon() {
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

    List<Color> getLibraryGradient() {
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: imagePath.startsWith('http')
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: getLibraryGradient(),
                ),
          image: imagePath.startsWith('http')
              ? DecorationImage(
                  image: NetworkImage(imagePath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.2),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!imagePath.startsWith('http')) ...[
                Expanded(
                  child: Center(
                    child: Icon(
                      getLibraryIcon(),
                      color: Colors.white.withOpacity(0.9),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count Games',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildSteamStat(
                  icon: Icons.sports_esports,
                  label: 'Games Played',
                  value: '120',
                ),
                const SizedBox(height: 16),
                _buildSteamStat(
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  value: '350',
                ),
                const SizedBox(height: 16),
                _buildSteamStat(
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
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.accentColor,
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
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
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
