import 'package:ludicapp/core/enums/activity_type.dart';

class UserActivity {
  final int id;
  final ActivityType activityType;
  final DateTime timestamp;
  final String gameTitle;
  final String? gameImageUrl;
  final int gameId;
  
  // For rating activity
  final double? rating;
  final String? review;
  
  // For saving activity
  final String? collectionName;
  
  // For list activity
  final String? listName;
  final int? listId;
  
  // For comment activity
  final String? comment;

  const UserActivity({
    required this.id,
    required this.activityType,
    required this.timestamp,
    required this.gameTitle,
    required this.gameId,
    this.gameImageUrl,
    this.rating,
    this.review,
    this.collectionName,
    this.listName,
    this.listId,
    this.comment,
  });
  
  // Factory to create a mock activity
  factory UserActivity.mock({
    required int id,
    required ActivityType activityType,
    DateTime? timestamp,
    String? gameTitle,
    String? gameImageUrl,
  }) {
    final mockTimestamp = timestamp ?? DateTime.now().subtract(Duration(minutes: id * 30));
    final mockGameTitle = gameTitle ?? 'Game Title $id';
    
    switch (activityType) {
      case ActivityType.rate:
        return UserActivity(
          id: id,
          activityType: activityType,
          timestamp: mockTimestamp,
          gameTitle: mockGameTitle,
          gameId: 1000 + id,
          gameImageUrl: gameImageUrl,
          rating: (3.0 + (id % 8)).roundToDouble(),
          review: id % 3 == 0 ? 'This game was amazing! Highly recommended.' : null,
        );
      
      case ActivityType.save:
        return UserActivity(
          id: id,
          activityType: activityType,
          timestamp: mockTimestamp,
          gameTitle: mockGameTitle,
          gameId: 1000 + id,
          gameImageUrl: gameImageUrl,
          collectionName: ['Favorites', 'Play Later', 'Completed'][id % 3],
        );
      
      case ActivityType.addToList:
        return UserActivity(
          id: id,
          activityType: activityType,
          timestamp: mockTimestamp,
          gameTitle: mockGameTitle,
          gameId: 1000 + id,
          gameImageUrl: gameImageUrl,
          listName: ['RPG Games', 'Strategy', 'Indie Gems', 'Must Play'][id % 4],
          listId: 100 + (id % 4),
        );
      
      case ActivityType.comment:
        return UserActivity(
          id: id,
          activityType: activityType,
          timestamp: mockTimestamp,
          gameTitle: mockGameTitle,
          gameId: 1000 + id,
          gameImageUrl: gameImageUrl,
          comment: [
            'This game has incredible graphics!',
            'The storyline could be better, but gameplay is solid.',
            'One of the best games I\'ve played this year!',
            'Multiplayer mode is very addictive.',
          ][id % 4],
        );
    }
  }
  
  // Generate a list of mock activities
  static List<UserActivity> generateMockActivities({int count = 10}) {
    final List<UserActivity> activities = [];
    final List<String> mockImageUrls = [
      'https://via.placeholder.com/300x180/2C3E50/FFFFFF?text=Game+1',
      'https://via.placeholder.com/300x180/8E44AD/FFFFFF?text=Game+2',
      'https://via.placeholder.com/300x180/16A085/FFFFFF?text=Game+3',
      'https://via.placeholder.com/300x180/D35400/FFFFFF?text=Game+4',
      'https://via.placeholder.com/300x180/7F8C8D/FFFFFF?text=Game+5',
    ];
    
    final activityTypes = ActivityType.values;
    
    for (int i = 0; i < count; i++) {
      final activityType = activityTypes[i % activityTypes.length];
      activities.add(
        UserActivity.mock(
          id: i,
          activityType: activityType,
          gameImageUrl: mockImageUrls[i % mockImageUrls.length],
          timestamp: DateTime.now().subtract(Duration(hours: i * 3)),
          gameTitle: 'Game Title ${i + 1}'
        )
      );
    }
    
    return activities;
  }
} 