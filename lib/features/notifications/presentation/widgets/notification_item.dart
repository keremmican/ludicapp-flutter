import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:ludicapp/features/notifications/domain/entities/notification.dart' as app_notification;
import 'package:ludicapp/theme/app_theme.dart';

class NotificationItem extends StatelessWidget {
  final app_notification.Notification notification;

  const NotificationItem({super.key, required this.notification});

  IconData _getIconForType(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.follow:
        return Icons.person_add_alt_1;
      case app_notification.NotificationType.reviewLike:
        return Icons.favorite;
      case app_notification.NotificationType.listFollow:
        return Icons.list_alt_rounded;
      case app_notification.NotificationType.appInfo:
        return Icons.info;
    }
  }

  Color _getIconColor(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.follow:
        return Colors.blue;
      case app_notification.NotificationType.reviewLike:
        return Colors.red;
      case app_notification.NotificationType.listFollow:
        return Colors.green;
      case app_notification.NotificationType.appInfo:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final IconData iconData = _getIconForType(notification.type);
    final Color iconColor = _getIconColor(notification.type);
    final String timeAgo = _formatTimestamp(notification.timestamp);

    // Dark mode için uygun renkler
    final Color cardColor = isDark 
        ? const Color(0xFF2A2A2A) // Koyu gri (dark mode için card)
        : Colors.white;        // Beyaz (light mode için)
    
    final Color textColor = isDark
        ? Colors.white
        : Colors.black87;
    
    final Color secondaryTextColor = isDark
        ? Colors.white70
        : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(iconData, color: iconColor),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (notification.contentPreview != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      notification.contentPreview!,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4.0),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8.0, top: 4.0),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  // Helper function to format timestamp (replace with a proper time ago library if needed)
  String _formatTimestamp(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 1) {
      return DateFormat('MMM d, yyyy').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 