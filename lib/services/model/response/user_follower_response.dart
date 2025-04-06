import 'package:flutter/foundation.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';

@immutable
class UserFollowerResponse {
  final int? userId;
  final String username;
  final String? profilePhotoUrl;
  final ProfilePhotoType profilePhotoType;
  bool isFollowing;
  bool isProcessing;

  UserFollowerResponse({
    required this.userId,
    required this.username,
    this.profilePhotoUrl,
    required this.profilePhotoType,
    required this.isFollowing,
    this.isProcessing = false,
  });

  factory UserFollowerResponse.fromJson(Map<String, dynamic> json) {
    // Log the raw JSON for debugging
    print('Raw JSON for user ${json['userId']}: $json');
    
    // Check both possible field names: 'isFollowing' and 'following'
    final rawIsFollowing = json['isFollowing'] ?? json['following'];
    print('Raw following value: $rawIsFollowing (type: ${rawIsFollowing?.runtimeType})');
    
    // More flexible parsing of isFollowing
    bool isFollowing;
    if (rawIsFollowing == null) {
      isFollowing = false;
    } else if (rawIsFollowing is bool) {
      isFollowing = rawIsFollowing;
    } else if (rawIsFollowing is String) {
      isFollowing = rawIsFollowing.toLowerCase() == 'true';
    } else if (rawIsFollowing is num) {
      isFollowing = rawIsFollowing != 0;
    } else {
      print('WARNING: Unknown following format: $rawIsFollowing');
      isFollowing = false;
    }
    
    return UserFollowerResponse(
      userId: json['userId'] as int?,
      username: json['username'] as String? ?? 'Unknown User',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      profilePhotoType: ProfilePhotoType.fromString(json['profilePhotoType'] as String?),
      isFollowing: isFollowing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profilePhotoUrl': profilePhotoUrl,
      'profilePhotoType': profilePhotoType.name,
      'isFollowing': isFollowing,
    };
  }
} 