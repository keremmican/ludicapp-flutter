import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/core/enums/activity_type.dart';
import 'package:ludicapp/models/user_activity.dart';
import 'dart:ui'; // For ImageFilter

// Simple Speech Bubble Widget (Copied from user_activities_page.dart for now)
class SpeechBubble extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double maxWidth;
  final int maxLines;

  const SpeechBubble({
    Key? key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.maxWidth = 200.0, // Adjusted for card width
    this.maxLines = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Slightly smaller padding
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(4), 
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontStyle: FontStyle.italic),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      ),
    );
  }
}

class ActivityItemCard extends StatelessWidget {
  final UserActivity activity;
  final String? userProfileImageUrl; // Added parameter for user avatar
  
  const ActivityItemCard({
    Key? key,
    required this.activity,
    this.userProfileImageUrl, // Initialize parameter
  }) : super(key: key);

  // Helper to get theme colors
  (Color, IconData) _getActivityTheme(ActivityType type) {
    switch (type) {
      case ActivityType.rate: return (Colors.amber, Icons.star_rounded);
      case ActivityType.save: return (Colors.teal, Icons.bookmark_rounded);
      case ActivityType.addToList: return (Colors.purpleAccent, Icons.playlist_add_rounded);
      case ActivityType.comment: return (Colors.lightBlue, Icons.chat_bubble_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (themeColor, activityIcon) = _getActivityTheme(activity.activityType);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 220, // Adjusted width slightly
      margin: const EdgeInsets.only(right: 12), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), 
        child: Stack(
          alignment: Alignment.center, // Align content centrally by default
          children: [
            // Blurred Background Image
            Positioned.fill(
              child: _buildBackgroundImage(),
            ),
            
            // Simplified Overlay for contrast
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1), // Less blur
                child: Container(
                  decoration: BoxDecoration(
                    // Remove gradient, use single dark overlay
                    color: Colors.black.withOpacity(0.55), 
                  ),
                ),
              ),
            ),
            
            // Central Content Area (dynamically built)
            Padding(
              padding: const EdgeInsets.only(top: 45, bottom: 55, left: 15, right: 15), // Adjust padding to account for avatar and icon positions
              child: _buildCardContentDetails(context, activity, themeColor),
            ),

            // Top-Left: User Profile Picture
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                radius: 16, // Slightly smaller avatar
                backgroundColor: Colors.grey[800], // Fallback color
                backgroundImage: (userProfileImageUrl != null && userProfileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(userProfileImageUrl!)
                    : null,
                child: (userProfileImageUrl == null || userProfileImageUrl!.isEmpty)
                  ? Icon(Icons.person_outline, size: 18, color: Colors.grey[500]) // Fallback icon
                  : null,
              ),
            ),

            // Top-Right: Activity Icon Badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                   color: themeColor, // Use theme color for badge background
                   shape: BoxShape.circle,
                   boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 5, offset: Offset(0, 2)) ]
                ),
                child: Icon(activityIcon, color: Colors.white, size: 18),
              ),
            ),

            // Bottom-Left: Small Game Cover
            Positioned(
              bottom: 10,
              left: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: CachedNetworkImage(
                  imageUrl: activity.gameImageUrl ?? '', // Handle null
                  width: 35,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 35, height: 50,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 35, height: 50,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    child: Icon(Icons.image_not_supported_rounded, size: 18, color: Colors.grey[500]),
                  ),
                ),
              ),
            ),

            // Bottom-Right: Timestamp
             Positioned(
              bottom: 12,
              right: 12,
              child: Text(
                _getTimeAgo(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9), // Slightly more opaque
                  fontWeight: FontWeight.w500,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 2)] // Stronger shadow for contrast
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    if (activity.gameImageUrl != null && activity.gameImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: activity.gameImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[850],
          child: Icon(Icons.videogame_asset_off_outlined, color: Colors.white24, size: 40),
        ),
      );
    } else {
      // Fallback gradient if no image
      final (themeColor, _) = _getActivityTheme(activity.activityType);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [themeColor.withOpacity(0.6), Colors.grey[850]!],
          ),
        ),
        child: const Center(child: Icon(Icons.videogame_asset_off_outlined, color: Colors.white24, size: 40)),
      );
    }
  }

  // Builds the central content based on activity type
  Widget _buildCardContentDetails(BuildContext context, UserActivity activity, Color themeColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Consistent white text style with shadow for readability
    const TextStyle titleStyle = TextStyle(
      fontSize: 15, 
      fontWeight: FontWeight.bold, 
      color: Colors.white, 
      shadows: [Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1,1))]
    );
    final TextStyle contentStyle = TextStyle(
      fontSize: 13, 
      color: Colors.white.withOpacity(0.95), 
      shadows: const [Shadow(color: Colors.black87, blurRadius: 2)]
    );
    final TextStyle subtitleStyle = TextStyle(
      fontSize: 12, 
      color: Colors.white.withOpacity(0.8), 
      shadows: const [Shadow(color: Colors.black87, blurRadius: 2)]
    );

     switch (activity.activityType) {
      case ActivityType.rate:
        return Column(
          mainAxisSize: MainAxisSize.min, // Take minimum space needed
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Text(
              activity.gameTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: titleStyle.copyWith(fontSize: 14), // Slightly smaller title for rating
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0), 
                    child: Icon(
                      index < (activity.rating ?? 0) / 2 ? Icons.star_rounded : Icons.star_border_rounded,
                      color: themeColor, // Use theme color for stars
                      size: 20, 
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${activity.rating?.toStringAsFixed(1) ?? '-'}/10',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: themeColor.withOpacity(0.9), // Use theme color for rating text
                shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
              ),
            ),
          ],
        );
        
      case ActivityType.save:
      case ActivityType.addToList:
         String actionText = activity.activityType == ActivityType.save ? 'Saved to' : 'Added to';
         String targetName = activity.activityType == ActivityType.save
              ? (activity.collectionName ?? "collection")
              : (activity.listName ?? "list");

        return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                activity.gameTitle,
                maxLines: 2, // Allow two lines for title
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              const SizedBox(height: 8),
              Text(
                actionText,
                style: subtitleStyle,
              ),
              const SizedBox(height: 2),
              Text(
                '"$targetName"' , 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: contentStyle.copyWith(fontWeight: FontWeight.w600),
              ),
            ]
          );
        
      case ActivityType.comment:
        if (activity.comment == null || activity.comment!.isEmpty) {
          // Fallback if no comment text
          return Text(
              'Commented on\n${activity.gameTitle}', 
              textAlign: TextAlign.center,
              style: contentStyle,
           );
        }
        // Use a slightly transparent background for the bubble for better blending
        Color bubbleBgColor = isDark 
            ? Colors.white.withOpacity(0.1) 
            : Colors.black.withOpacity(0.2);
        return Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.center, // Center the bubble
           children: [
             SpeechBubble(
               text: activity.comment!, 
               backgroundColor: bubbleBgColor, 
               textColor: Colors.white, // Ensure bubble text is white
               maxWidth: 160, // Limit bubble width further
             ),
           ],
         );
    }
  }

  // Updated description generation (not used in this layout directly)
  String _getActivityDescription() {
    // ... (keep the logic but it might not be displayed directly anymore)
     switch (activity.activityType) {
      case ActivityType.rate:
        String reviewSnippet = activity.review != null && activity.review!.isNotEmpty
            ? ': "${activity.review!.length > 50 ? activity.review!.substring(0, 50) + '...' : activity.review!}"'
            : '';
        return 'Rated ${activity.rating?.toStringAsFixed(1) ?? '-'}/10${reviewSnippet}';
      case ActivityType.save:
        return 'Saved to ${activity.collectionName ?? "collection"}';
      case ActivityType.addToList:
        return 'Added to list "${activity.listName ?? "My List"}"';
      case ActivityType.comment:
        String commentSnippet = activity.comment != null && activity.comment!.isNotEmpty
            ? '"${activity.comment!.length > 60 ? activity.comment!.substring(0, 60) + '...' : activity.comment!}"'
            : 'Commented on this game';
        return commentSnippet;
    }
  }

  String _getTimeAgo() {
    final difference = DateTime.now().difference(activity.timestamp);
    
    if (difference.inDays > 365) {
       return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 