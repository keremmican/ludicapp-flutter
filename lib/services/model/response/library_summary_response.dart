import 'package:flutter/foundation.dart';
import 'package:ludicapp/core/enums/library_type.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';

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
  final DateTime? updatedAt;
  final String? ownerUsername;
  final String? ownerProfilePhotoUrl;
  final ProfilePhotoType ownerProfilePhotoType;

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
    this.updatedAt,
    this.ownerUsername,
    this.ownerProfilePhotoUrl,
    this.ownerProfilePhotoType = ProfilePhotoType.DEFAULT_1,
  });

  /// Creates an instance from a JSON map.
  factory LibrarySummaryResponse.fromJson(Map<String, dynamic> json) {
    int? ownerId;
    String? ownerUsername;
    String? ownerProfilePhotoUrl;
    ProfilePhotoType ownerProfilePhotoType = ProfilePhotoType.DEFAULT_1;

    // Parse owner information from the new backend structure
    if (json.containsKey('owner') && json['owner'] != null) {
      final Map<String, dynamic> ownerJson = json['owner'] as Map<String, dynamic>;
      
      // Parse owner's userId
      if (ownerJson.containsKey('userId') && ownerJson['userId'] != null) {
        if (ownerJson['userId'] is int) {
          ownerId = ownerJson['userId'] as int;
        } else if (ownerJson['userId'] is num) {
          ownerId = (ownerJson['userId'] as num).toInt();
        } else if (ownerJson['userId'] is String) {
          ownerId = int.tryParse(ownerJson['userId'] as String);
        }
      }
      
      // Parse owner's username and profilePhotoUrl
      ownerUsername = ownerJson['username'] as String?;
      ownerProfilePhotoUrl = ownerJson['profilePhotoUrl'] as String?;
      
      // Parse the profile photo type
      if (ownerJson.containsKey('profilePhotoType') && ownerJson['profilePhotoType'] != null) {
        ownerProfilePhotoType = ProfilePhotoType.fromString(ownerJson['profilePhotoType'] as String?);
      }
    } 
    // Fallback to legacy format for backward compatibility
    else {
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
      
      // Try to get legacy username and profile photo fields if present
      ownerUsername = json['ownerUsername'] as String?;
      ownerProfilePhotoUrl = json['ownerProfilePhotoUrl'] as String?;
      
      // Try to get profile photo type from the root JSON
      if (json.containsKey('ownerProfilePhotoType') && json['ownerProfilePhotoType'] != null) {
        ownerProfilePhotoType = ProfilePhotoType.fromString(json['ownerProfilePhotoType'] as String?);
      }
    }

    final isPrivate = json['isPrivate'] as bool? ?? false;
    final followerCount = json['followerCount'] as int?;
    final isCurrentUserFollowing = json['isCurrentUserFollowing'] as bool?;
    
    DateTime? updatedAt;
    if (json.containsKey('updatedAt') && json['updatedAt'] != null) {
      try {
        // Handle updateAt being a String or a List
        if (json['updatedAt'] is String) {
          updatedAt = DateTime.parse(json['updatedAt'] as String);
        } else if (json['updatedAt'] is List) {
          // Handle the format [year, month, day, hour, minute, second, nanoseconds]
          final List<dynamic> dateList = json['updatedAt'] as List<dynamic>;
          if (dateList.length >= 6) {
            int year = dateList[0] as int? ?? 2020;
            int month = dateList[1] as int? ?? 1;
            int day = dateList[2] as int? ?? 1;
            int hour = dateList[3] as int? ?? 0;
            int minute = dateList[4] as int? ?? 0;
            int second = dateList[5] as int? ?? 0;
            int millisecond = 0;
            
            // Handle optional nanoseconds (7th element)
            if (dateList.length >= 7) {
              // Convert nanoseconds to milliseconds
              millisecond = ((dateList[6] as int?) ?? 0) ~/ 1000000;
            }
            
            updatedAt = DateTime(year, month, day, hour, minute, second, millisecond);
          }
        }
      } catch (e) {
        print('Error parsing updatedAt date: $e');
      }
    }
    
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
      updatedAt: updatedAt,
      ownerUsername: ownerUsername,
      ownerProfilePhotoUrl: ownerProfilePhotoUrl,
      ownerProfilePhotoType: ownerProfilePhotoType,
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
      'updatedAt': updatedAt?.toIso8601String(),
      'ownerUsername': ownerUsername,
      'ownerProfilePhotoUrl': ownerProfilePhotoUrl,
      'ownerProfilePhotoType': ownerProfilePhotoType.name,
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
    DateTime? updatedAt,
    String? ownerUsername,
    String? ownerProfilePhotoUrl,
    ProfilePhotoType? ownerProfilePhotoType,
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
      updatedAt: updatedAt ?? this.updatedAt,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerProfilePhotoUrl: ownerProfilePhotoUrl ?? this.ownerProfilePhotoUrl,
      ownerProfilePhotoType: ownerProfilePhotoType ?? this.ownerProfilePhotoType,
    );
  }
} 