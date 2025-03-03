import 'user_status.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';

class ProfileResponse {
  final String username;
  final double level;
  final int followerCount;
  final int followingCount;
  final UserStatus userStatus;
  final bool? isFollowing;
  List<LibrarySummaryResponse> librarySummaries;

  ProfileResponse({
    required this.username,
    required this.level,
    required this.followerCount,
    required this.followingCount,
    required this.userStatus,
    this.isFollowing,
    this.librarySummaries = const [],
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
      isFollowing: json['isFollowing'] as bool?,
      librarySummaries: (json['librarySummaries'] as List<dynamic>?)
          ?.map((e) => LibrarySummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'level': level,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'userStatus': userStatus.toString().split('.').last,
      'isFollowing': isFollowing,
      'librarySummaries': librarySummaries.map((e) => e.toJson()).toList(),
    };
  }
} 