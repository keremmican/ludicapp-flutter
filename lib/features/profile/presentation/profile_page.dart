import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/library_category_card.dart';
import 'package:ludicapp/features/profile/presentation/widgets/followers_page.dart';
import 'package:ludicapp/features/profile/presentation/widgets/following_page.dart';
import 'package:ludicapp/features/profile/presentation/widgets/profile_header.dart';
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

  const ProfilePage({Key? key}) : super(key: key); // Added const constructor

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Part: Profile Header
          ProfileHeader(
            level: 21,
            progress: 0.65, // 65% progress
            followingCount: 150,
            followersCount: 200,
            onSettingsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
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

          const SizedBox(height: 20),

          // My Library Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: const Text(
              'My Library',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          _buildGameLibrary(context),

          // Steam Profile Section
          _buildSteamProfile(context),
        ],
      ),
    );
  }

  Widget _buildGameLibrary(BuildContext context) {
    final categories = [
      {
        'title': 'Top Matches',
        'image': mockImages[Random().nextInt(mockImages.length)]
      },
      {
        'title': 'Saved',
        'image': mockImages[Random().nextInt(mockImages.length)]
      },
      {
        'title': 'Rated',
        'image': mockImages[Random().nextInt(mockImages.length)]
      },
      {
        'title': 'New Releases',
        'image': mockImages[Random().nextInt(mockImages.length)]
      },
      {
        'title': 'Coming Soon',
        'image': mockImages[Random().nextInt(mockImages.length)]
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two cards per row
          crossAxisSpacing: 8, // Reduced horizontal spacing
          mainAxisSpacing: 8, // Reduced vertical spacing
          childAspectRatio: 4.0, // Width to height ratio of 4:1
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return LibraryCategoryCard(
            title: category['title']!,
            imagePath: category['image']!,
            onTap: () {
              print('${category['title']} clicked!');
              // Navigate to RelatedGamesPage with category title
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
      ),
    );
  }

  Widget _buildSteamProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Steam Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Games Played: 120',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 5),
                Text(
                  'Achievements: 350',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 5),
                Text(
                  'Hours Played: 540',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
