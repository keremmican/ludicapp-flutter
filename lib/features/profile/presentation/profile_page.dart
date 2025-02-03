import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/library_category_card.dart';
import 'package:ludicapp/features/profile/presentation/widgets/followers_page.dart';
import 'package:ludicapp/features/profile/presentation/widgets/following_page.dart';
import 'package:ludicapp/features/profile/presentation/widgets/profile_header.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'dart:math';
import 'settings_page.dart';
import 'related_games_page.dart';

class ProfilePage extends StatelessWidget {
  static const List<String> mockImages = [
    'lib/assets/images/mock_games/game1.jpg',
    'lib/assets/images/mock_games/game2.jpg',
    'lib/assets/images/mock_games/game3.jpg',
    'lib/assets/images/mock_games/game4.jpg',
    'lib/assets/images/mock_games/game5.jpg',
    'lib/assets/images/mock_games/game6.jpg',
  ];

  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileData = SplashScreen.profileData;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Part: Profile Header
          ProfileHeader(
            username: profileData?.username ?? 'Guest User',
            level: profileData?.level.toInt() ?? 0,
            progress: (profileData?.level ?? 0) % 1,
            followingCount: profileData?.followingCount ?? 0,
            followersCount: profileData?.followerCount ?? 0,
            onSettingsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
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

          const SizedBox(height: 80),

          // My Library Section
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

          // Steam Profile Section
          _buildSteamProfile(context),
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
