import 'package:flutter/foundation.dart';

// Based on the Java DTO: com.ludic.ludicapp.library.dto.UserGameLibraryDto
@immutable
class UserGameLibrary {
  final int id;
  final String title;
  final String type; // Corresponds to LibraryType enum (e.g., "CUSTOM")
  final int userId;
  final bool isPrivate;
  final List<int> gameIds;

  const UserGameLibrary({
    required this.id,
    required this.title,
    required this.type,
    required this.userId,
    required this.isPrivate,
    required this.gameIds,
  });

  factory UserGameLibrary.fromJson(Map<String, dynamic> json) {
    // Add extra null checks for robustness
    final id = json['id'] as int? ?? 0;
    final title = json['title'] as String? ?? 'Untitled';
    final type = json['type'] as String? ?? 'CUSTOM'; // Default to CUSTOM if missing
    final userId = json['userId'] as int? ?? 0;
    final isPrivate = json['isPrivate'] as bool? ?? false;
    final gameIdsList = json['gameIds'] as List<dynamic>?;
    final gameIds = gameIdsList != null 
        ? List<int>.from(gameIdsList.map((e) => e as int? ?? 0)) 
        : <int>[];
        
    return UserGameLibrary(
      id: id,
      title: title,
      type: type,
      userId: userId,
      isPrivate: isPrivate,
      gameIds: gameIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'userId': userId,
      'isPrivate': isPrivate,
      'gameIds': gameIds,
    };
  }
} 