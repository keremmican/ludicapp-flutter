import 'package:meta/meta.dart';

enum NotificationType {
  follow,
  reviewLike,
  listFollow,
  appInfo,
}

@immutable
class Notification {
  final String id;
  final NotificationType type;
  final String senderName; // Relevant for follow, reviewLike, listFollow
  final String? contentPreview; // e.g., review snippet, list name
  final String message; // Main notification text
  final DateTime timestamp;
  final bool isRead;
  final String? avatarUrl; // Optional: URL for sender's avatar

  const Notification({
    required this.id,
    required this.type,
    required this.senderName,
    this.contentPreview,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
  });

  // Factory constructor for app info type where senderName might not be relevant
  factory Notification.appInfo({
    required String id,
    required String message,
    required DateTime timestamp,
    bool isRead = false,
  }) {
    return Notification(
      id: id,
      type: NotificationType.appInfo,
      senderName: 'LudicApp', // Or your app's name
      message: message,
      timestamp: timestamp,
      isRead: isRead,
      // Optionally add an app logo URL
      // avatarUrl: 'path/to/app_logo.png', 
    );
  }
} 