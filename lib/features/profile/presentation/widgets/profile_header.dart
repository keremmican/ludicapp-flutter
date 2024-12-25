import 'package:flutter/material.dart';
import 'level_component.dart';

class ProfileHeader extends StatelessWidget {
  final int level;
  final double progress; // Value between 0.0 and 1.0
  final int followingCount;
  final int followersCount;
  final VoidCallback onSettingsPressed;
  final VoidCallback onFollowingPressed;
  final VoidCallback onFollowersPressed;

  const ProfileHeader({
    Key? key,
    required this.level,
    required this.progress,
    required this.followingCount,
    required this.followersCount,
    required this.onSettingsPressed,
    required this.onFollowingPressed,
    required this.onFollowersPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Background and Profile Photo with Settings Icon
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Background Photo
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/images/background_profile.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),

            // Settings Icon Positioned at Top Right
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: onSettingsPressed,
                icon: const Icon(Icons.settings, color: Color(0xFFBFE429)),
              ),
            ),

            // Profile Photo
            Positioned(
              top: 100,
              left: MediaQuery.of(context).size.width / 2 - 50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  image: const DecorationImage(
                    image: AssetImage('lib/assets/images/profile_photo.jpg'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ],
        ),

        // Space between Profile Photo and Stats
        const SizedBox(height: 50), // Azaltıldı: 60'dan 50'ye

        // Stats Container
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2), // Azaltıldı: 8'den 4'e
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Level Component
              LevelComponent(
                level: level,
                progress: progress,
              ),

              // Followers Stat (Clickable)
              GestureDetector(
                onTap: onFollowersPressed,
                child: Column(
                  children: [
                    Text(
                      '$followersCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Followers',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Following Stat (Clickable)
              GestureDetector(
                onTap: onFollowingPressed,
                child: Column(
                  children: [
                    Text(
                      '$followingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Following',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10), // Ayarlanabilir boşluk

        // Diğer öğeler veya boşluklar eklenebilir
      ],
    );
  }
}
