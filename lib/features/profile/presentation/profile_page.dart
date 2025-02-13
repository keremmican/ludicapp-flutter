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
import 'dart:math';
import 'settings_page.dart';
import 'related_games_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  final bool fromSearch;

  const ProfilePage({
    Key? key, 
    this.userId,
    this.fromSearch = false,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserRepository _userRepository = UserRepository();
  final TokenService _tokenService = TokenService();
  ProfileResponse? _profileData;
  bool _isCurrentUser = false;
  bool _isLoading = true;
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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUserId = await _tokenService.getUserId();
      _isCurrentUser = widget.userId == null || widget.userId == currentUserId.toString();

      if (_isCurrentUser) {
        // If it's the current user's profile, use the cached data from splash screen
        setState(() {
          _profileData = SplashScreen.profileData;
          _isLoading = false;
        });
      } else {
        // If it's another user's profile, fetch from API
        final response = await _userRepository.fetchUserProfile(userId: widget.userId);
        setState(() {
          _profileData = response;
          _isLoading = false;
          _isFollowing = response.isFollowing ?? false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading profile')),
      );
    }

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
    final categories = [
      {
        'title': 'Top Matches',
        'image': mockImages[Random().nextInt(mockImages.length)],
        'count': '24',
      },
      {
        'title': 'Saved',
        'image': mockImages[Random().nextInt(mockImages.length)],
        'count': '12',
      },
      {
        'title': 'Rated',
        'image': mockImages[Random().nextInt(mockImages.length)],
        'count': '36',
      },
      {
        'title': 'New Releases',
        'image': mockImages[Random().nextInt(mockImages.length)],
        'count': '8',
      },
      {
        'title': 'Coming Soon',
        'image': mockImages[Random().nextInt(mockImages.length)],
        'count': '15',
      },
    ];

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
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          context,
          title: category['title']!,
          imagePath: category['image']!,
          count: category['count']!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RelatedGamesPage(categoryTitle: category['title']!),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
