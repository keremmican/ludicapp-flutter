import 'package:flutter/foundation.dart';
import 'package:ludicapp/core/enums/library_type.dart';

/// Represents a summary of a user library.
@immutable
class LibrarySummaryResponse {
  final int id;
  final int? ownerUserId;
  final String libraryName;
  final String? coverUrl;
  final int gameCount;
  final LibraryType libraryType;
  final bool isPrivate;
  final int? followerCount;
  final bool? isCurrentUserFollowing;

  const LibrarySummaryResponse({
    required this.id,
    required this.ownerUserId,
    required this.libraryName,
    this.coverUrl,
    required this.gameCount,
    required this.libraryType,
    required this.isPrivate,
    this.followerCount,
    this.isCurrentUserFollowing,
  });

  /// Creates an instance from a JSON map.
  factory LibrarySummaryResponse.fromJson(Map<String, dynamic> json) {
    int? ownerId;
    if (json.containsKey('userId') && json['userId'] != null) {
      if (json['userId'] is int) {
        ownerId = json['userId'] as int;
      } else if (json['userId'] is num) {
        ownerId = (json['userId'] as num).toInt();
      }
    } else if (json.containsKey('ownerUserId') && json['ownerUserId'] != null) {
       if (json['ownerUserId'] is int) {
        ownerId = json['ownerUserId'] as int;
      } else if (json['ownerUserId'] is num) {
        ownerId = (json['ownerUserId'] as num).toInt();
      }
    }

    final isPrivate = json['isPrivate'] as bool? ?? false;
    final followerCount = json['followerCount'] as int?;
    final isCurrentUserFollowing = json['isCurrentUserFollowing'] as bool?;
    
    return LibrarySummaryResponse(
      id: json['id'] as int? ?? 0,
      ownerUserId: ownerId,
      libraryName: json['libraryName'] as String? ?? 'Unknown Library',
      coverUrl: json['coverUrl'] as String?,
      gameCount: json['gameCount'] as int? ?? 0,
      libraryType: LibraryType.fromString(json['libraryType'] as String?),
      isPrivate: isPrivate,
      followerCount: followerCount,
      isCurrentUserFollowing: isCurrentUserFollowing,
    );
  }

  /// Converts this instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': ownerUserId,
      'libraryName': libraryName,
      'coverUrl': coverUrl,
      'gameCount': gameCount,
      'libraryType': libraryType.toJsonString(),
      'isPrivate': isPrivate,
      'followerCount': followerCount,
      'isCurrentUserFollowing': isCurrentUserFollowing,
    };
  }

  String get displayName {
    switch (libraryName) {
      case 'SAVED_LIBRARY':
        return 'Saved';
      case 'HID_LIBRARY':
        return 'Hidden';
      case 'RATED_LIBRARY':
        return 'Rated';
      case 'CURRENTLY_PLAYING_LIBRARY':
        return 'Currently Playing';
      default:
        return libraryName;
    }
  }

  LibrarySummaryResponse copyWith({
    int? id,
    int? ownerUserId,
    String? libraryName,
    String? coverUrl,
    int? gameCount,
    LibraryType? libraryType,
    bool? isPrivate,
    int? followerCount,
    bool? isCurrentUserFollowing,
  }) {
    return LibrarySummaryResponse(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      libraryName: libraryName ?? this.libraryName,
      coverUrl: coverUrl ?? this.coverUrl,
      gameCount: gameCount ?? this.gameCount,
      libraryType: libraryType ?? this.libraryType,
      isPrivate: isPrivate ?? this.isPrivate,
      followerCount: followerCount ?? this.followerCount,
      isCurrentUserFollowing: isCurrentUserFollowing ?? this.isCurrentUserFollowing,
    );
  }
} 