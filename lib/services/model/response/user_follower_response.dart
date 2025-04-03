import 'package:flutter/foundation.dart';

@immutable
class UserFollowerResponse {
  final int? userId;
  final String username;
  final String? profilePhotoUrl;
  bool isFollowing;
  bool isProcessing;

  UserFollowerResponse({
    required this.userId,
    required this.username,
    this.profilePhotoUrl,
    required this.isFollowing,
    this.isProcessing = false,
  });

  factory UserFollowerResponse.fromJson(Map<String, dynamic> json) {
    return UserFollowerResponse(
      userId: json['userId'] as int?,
      username: json['username'] as String? ?? 'Unknown User',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profilePhotoUrl': profilePhotoUrl,
      'isFollowing': isFollowing,
    };
  }
} 