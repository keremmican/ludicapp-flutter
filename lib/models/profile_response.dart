import 'user_status.dart';

class ProfileResponse {
  final String username;
  final double level;
  final int followerCount;
  final int followingCount;
  final UserStatus userStatus;

  ProfileResponse({
    required this.username,
    required this.level,
    required this.followerCount,
    required this.followingCount,
    required this.userStatus,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      username: json['username'] as String,
      level: json['level'] == null ? 0.0 : (json['level'] as num).toDouble(),
      followerCount: (json['followerCount'] ?? 0) as int,
      followingCount: (json['followingCount'] ?? 0) as int,
      userStatus: UserStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] as String),
        orElse: () => UserStatus.ACTIVE,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'level': level,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'userStatus': userStatus.toString().split('.').last,
    };
  }
} 