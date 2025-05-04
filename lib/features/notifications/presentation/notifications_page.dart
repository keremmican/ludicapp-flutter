import 'package:flutter/material.dart';
import 'package:ludicapp/features/notifications/domain/entities/notification.dart' as app_notification;
import 'package:ludicapp/features/notifications/presentation/widgets/notification_item.dart';
import 'package:ludicapp/theme/app_theme.dart';

// --- Mock Data ---
// In a real app, this would come from a state management solution (e.g., Riverpod)
final List<app_notification.Notification> _mockNotifications = [
  app_notification.Notification(
    id: '1',
    type: app_notification.NotificationType.follow,
    senderName: 'John Doe',
    message: 'John Doe started following you.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    isRead: false,
  ),
  app_notification.Notification(
    id: '2',
    type: app_notification.NotificationType.reviewLike,
    senderName: 'Jane Smith',
    message: 'Jane Smith liked your review on The Legend of Zelda.',
    contentPreview: '"An absolute masterpiece, redefined open-world gaming..."',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: false,
  ),
  app_notification.Notification(
    id: '3',
    type: app_notification.NotificationType.listFollow,
    senderName: 'Alex Green',
    message: 'Alex Green started following your "Top 10 RPGs" list.',
    contentPreview: '"My personal ranking of the best role-playing games..."',
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    isRead: true,
  ),
  app_notification.Notification.appInfo(
    id: '4',
    message: 'New feature update! You can now customize your profile theme.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  app_notification.Notification(
    id: '5',
    type: app_notification.NotificationType.reviewLike,
    senderName: 'Chris Taylor',
    message: 'Chris Taylor liked your review on Cyberpunk 2077.',
    contentPreview: '"Despite the rocky launch, the core experience is solid..."',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
  ),
];
// --- End Mock Data ---

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd get the list from your state/controller
    final List<app_notification.Notification> notifications = _mockNotifications;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Tema'ya göre arka plan rengini ayarla
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        // AppBar'ın rengini tema'ya göre ayarla
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        // Tema değiştiğinde başlık rengi de değişsin
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0, // Flat app bar
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No Notifications Yet!',
                style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textSecondaryDark, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return NotificationItem(notification: notifications[index]);
              },
            ),
    );
  }
}
