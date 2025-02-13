import 'package:flutter/material.dart';
import 'level_component.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final int level;
  final double progress;
  final int followingCount;
  final int followersCount;
  final VoidCallback? onSettingsPressed;
  final VoidCallback onFollowingPressed;
  final VoidCallback onFollowersPressed;

  const ProfileHeader({
    Key? key,
    required this.username,
    required this.level,
    required this.progress,
    required this.followingCount,
    required this.followersCount,
    this.onSettingsPressed,
    required this.onFollowingPressed,
    required this.onFollowersPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Image with Gradient Overlay
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/images/background_profile.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),

        // Settings Button
        if (onSettingsPressed != null) Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: onSettingsPressed,
              icon: const Icon(Icons.settings, color: Color(0xFFBFE429)),
            ),
          ),
        ),

        // Profile Info Container
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Profile Photo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  image: const DecorationImage(
                    image: AssetImage('lib/assets/images/profile_photo.jpg'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBFE429),
                    width: 2,
                  ),
                ),
              ),
              
              // Username
              const SizedBox(height: 8),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Stats Container
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Level Component
                    LevelComponent(
                      level: level,
                      progress: progress,
                    ),

                    _buildDivider(),

                    // Followers
                    _buildStat(
                      label: 'Followers',
                      value: followersCount.toString(),
                      onTap: onFollowersPressed,
                    ),

                    _buildDivider(),

                    // Following
                    _buildStat(
                      label: 'Following',
                      value: followingCount.toString(),
                      onTap: onFollowingPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
