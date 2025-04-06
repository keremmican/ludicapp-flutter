import 'package:flutter/material.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'level_component.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final int level;
  final double progress;
  final int followingCount;
  final int followersCount;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onEditProfilePressed;
  final VoidCallback onFollowingPressed;
  final VoidCallback onFollowersPressed;
  final String? profilePhotoUrl;
  final ProfilePhotoType profilePhotoType;
  // TODO: Add background image URL and type later if needed

  const ProfileHeader({
    Key? key,
    required this.username,
    required this.level,
    required this.progress,
    required this.followingCount,
    required this.followersCount,
    this.onSettingsPressed,
    this.onEditProfilePressed,
    required this.onFollowingPressed,
    required this.onFollowersPressed,
    required this.profilePhotoUrl,
    required this.profilePhotoType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background - Placeholder for now, replace with dynamic image later
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.6),
                Theme.of(context).colorScheme.secondary.withOpacity(0.6),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.5),
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
              icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
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
              // Profile Photo with Edit Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildProfilePhoto(context),
                  if (onEditProfilePressed != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit, size: 18),
                          color: Colors.white,
                          onPressed: onEditProfilePressed,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Username with Edit Button
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onEditProfilePressed != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onEditProfilePressed,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
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
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: LevelComponent(
                          level: level,
                          progress: progress,
                        ),
                      ),
                    ),

                    _buildDivider(),

                    // Followers - Make it wider for easier tapping
                    Expanded(
                      flex: 4,
                      child: _buildStat(
                        context: context,
                        label: 'Followers',
                        value: followersCount.toString(),
                        onTap: onFollowersPressed,
                      ),
                    ),

                    _buildDivider(),

                    // Following - Make it wider for easier tapping
                    Expanded(
                      flex: 4,
                      child: _buildStat(
                        context: context,
                        label: 'Following',
                        value: followingCount.toString(),
                        onTap: onFollowingPressed,
                      ),
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

  Widget _buildProfilePhoto(BuildContext context) {
    Widget imageWidget;

    if (profilePhotoType == ProfilePhotoType.CUSTOM && profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty) {
      // Custom URL
      imageWidget = CachedNetworkImage(
        imageUrl: profilePhotoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey.shade800), // Placeholder
        errorWidget: (context, url, error) => _buildDefaultPhotoPlaceholder(context), // Fallback on error
      );
    } else {
      // Default asset or fallback
      final String? assetPath = profilePhotoType.assetPath;
      if (assetPath != null) {
        imageWidget = Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultPhotoPlaceholder(context), // Fallback if asset missing
        );
      } else {
        // Fallback if type is CUSTOM but URL is missing, or asset path is null
        imageWidget = _buildDefaultPhotoPlaceholder(context);
      }
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade800, // Background for placeholder/loading
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias, // Clip the image to the rounded border
      child: imageWidget,
    );
  }

  // Fallback placeholder widget
  Widget _buildDefaultPhotoPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade700,
      child: Icon(
        Icons.person, 
        color: Colors.white.withOpacity(0.5), 
        size: 50,
      ),
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
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity, 
      child: GestureDetector(
        onTap: onTap, 
        behavior: HitTestBehavior.opaque, 
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value, 
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label, 
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
