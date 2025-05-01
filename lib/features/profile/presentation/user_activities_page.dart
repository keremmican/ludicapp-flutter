import 'package:flutter/material.dart';
import 'package:ludicapp/models/user_activity.dart';
import 'package:ludicapp/core/enums/activity_type.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Simple Speech Bubble Widget (Can be extracted to its own file later)
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
    this.maxWidth = 250.0,
    this.maxLines = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4), // Smaller radius for tail effect area
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 13.5, fontStyle: FontStyle.italic),
        softWrap: true,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class UserActivitiesPage extends StatefulWidget {
  final String? userId;
  final String username;

  const UserActivitiesPage({
    Key? key,
    this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<UserActivitiesPage> createState() => _UserActivitiesPageState();
}

class _UserActivitiesPageState extends State<UserActivitiesPage> {
  bool _isLoading = false;
  List<UserActivity> _activities = [];
  
  @override
  void initState() {
    super.initState();
    _loadActivities();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _loadActivities() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() {
        _activities = UserActivity.generateMockActivities(count: 25);
        _activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    }
  }
  
  (Color, IconData, String) _getActivityTheme(ActivityType type) {
    switch (type) {
      case ActivityType.rate: return (Colors.amber, Icons.star_rounded, 'Rated');
      case ActivityType.save: return (Colors.teal, Icons.bookmark_rounded, 'Saved');
      case ActivityType.addToList: return (Colors.purpleAccent, Icons.playlist_add_rounded, 'Added to List');
      case ActivityType.comment: return (Colors.lightBlue, Icons.chat_bubble_rounded, 'Commented');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.username}'s Activity",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).iconTheme.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading && _activities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildActivityList(_activities),
    );
  }
  
  Widget _buildActivityList(List<UserActivity> activities) {
    if (activities.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No activities found yet.',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityListItem(context, activity);
      },
    );
  }
  
  Widget _buildActivityListItem(BuildContext context, UserActivity activity) {
    final (themeColor, activityIcon, _) = _getActivityTheme(activity.activityType);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tapped on activity for: ${activity.gameTitle}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: activity.gameImageUrl ?? '',
                        width: 40,
                        height: 55,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 40, height: 55,
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 40, height: 55,
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          child: Icon(Icons.image_not_supported_rounded, size: 20, color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)
                    ),
                    child: Icon(activityIcon, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            activity.gameTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 15,
                              color: Theme.of(context).textTheme.titleMedium?.color
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                         padding: const EdgeInsets.only(top: 4.0),
                         child: Text(
                          _formatTimestamp(activity.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  _buildActivityContentDetails(context, activity, themeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityContentDetails(BuildContext context, UserActivity activity, Color themeColor) {
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodyMedium?.copyWith(fontSize: 14);
    final subtleStyle = textTheme.bodySmall?.copyWith(fontSize: 13.5);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (activity.activityType) {
      case ActivityType.rate:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Rated: ', 
              style: bodyStyle,
            ),
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 1.0), 
                child: Icon(
                  index < (activity.rating ?? 0) / 2 ? Icons.star_rounded : Icons.star_border_rounded,
                  color: themeColor, 
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${activity.rating?.toStringAsFixed(1) ?? '-'}/10)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: themeColor.withOpacity(0.9)
              ),
            ),
          ],
        );
        
      case ActivityType.save:
        return RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: bodyStyle, 
            children: [
              const TextSpan(text: 'Saved to '),
              TextSpan(
                text: '"${activity.collectionName ?? "collection"}"' , 
                style: const TextStyle(fontWeight: FontWeight.w600)
              ),
            ]
          )
        );
        
      case ActivityType.addToList:
        return RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: bodyStyle, 
            children: [
              const TextSpan(text: 'Added to list '),
              TextSpan(
                text: '"${activity.listName ?? "My List"}"' , 
                style: const TextStyle(fontWeight: FontWeight.w600)
              ),
            ]
          )
        );
        
      case ActivityType.comment:
        if (activity.comment == null || activity.comment!.isEmpty) {
          return Text('Commented on this game', style: subtleStyle);
        }
        return SpeechBubble(
          text: activity.comment!,
          backgroundColor: isDark ? themeColor.withOpacity(0.15) : themeColor.withOpacity(0.1),
          textColor: textTheme.bodyMedium!.color!,
        );
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 6) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
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