import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'user_status.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';

class ProfileResponse {
  final String username;
  final double level;
  final int followerCount;
  final int followingCount;
  final UserStatus userStatus;
  final bool? isFollowing;
  final String? profilePhotoUrl;
  final ProfilePhotoType profilePhotoType;
  List<LibrarySummaryResponse> librarySummaries;

  ProfileResponse({
    required this.username,
    required this.level,
    required this.followerCount,
    required this.followingCount,
    required this.userStatus,
    this.isFollowing,
    this.profilePhotoUrl,
    required this.profilePhotoType,
    this.librarySummaries = const [],
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    // Log raw JSON for debugging
    print('Raw ProfileResponse JSON: $json');
    
    // Check all possible field names for the following status
    final dynamic rawFollowingStatus = json['currentUserFollowing'] ?? json['isCurrentUserFollowing'] ?? json['isFollowing'];
    print('Raw following status: $rawFollowingStatus (type: ${rawFollowingStatus?.runtimeType})');
    
    // Parse the following status robustly
    bool? followingStatus;
    if (rawFollowingStatus == null) {
      followingStatus = null;
    } else if (rawFollowingStatus is bool) {
      followingStatus = rawFollowingStatus;
    } else if (rawFollowingStatus is String) {
      followingStatus = rawFollowingStatus.toLowerCase() == 'true';
    } else if (rawFollowingStatus is num) {
      followingStatus = rawFollowingStatus != 0;
    } else {
      print('WARNING: Unknown following status format: $rawFollowingStatus');
      followingStatus = null;
    }
    
    return ProfileResponse(
      username: json['username'] as String,
      level: json['level'] == null ? 0.0 : (json['level'] as num).toDouble(),
      followerCount: (json['followerCount'] ?? 0) as int,
      followingCount: (json['followingCount'] ?? 0) as int,
      userStatus: UserStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] as String? ?? 'ACTIVE'),
        orElse: () => UserStatus.ACTIVE,
      ),
      isFollowing: followingStatus,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      profilePhotoType: ProfilePhotoType.fromString(json['profilePhotoType'] as String?),
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
      'profilePhotoUrl': profilePhotoUrl,
      'profilePhotoType': profilePhotoType.name,
      'librarySummaries': librarySummaries.map((e) => e.toJson()).toList(),
    };
  }

  ProfileResponse copyWith({
    String? username,
    double? level,
    int? followerCount,
    int? followingCount,
    UserStatus? userStatus,
    bool? isFollowing,
    String? profilePhotoUrl,
    ProfilePhotoType? profilePhotoType,
    List<LibrarySummaryResponse>? librarySummaries,
  }) {
    return ProfileResponse(
      username: username ?? this.username,
      level: level ?? this.level,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      userStatus: userStatus ?? this.userStatus,
      isFollowing: isFollowing ?? this.isFollowing,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profilePhotoType: profilePhotoType ?? this.profilePhotoType,
      librarySummaries: librarySummaries ?? this.librarySummaries,
    );
  }
} 