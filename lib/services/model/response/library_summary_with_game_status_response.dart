import 'package:ludicapp/core/enums/library_type.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart'; // Import the actual base class
import 'package:flutter/foundation.dart';

@immutable
class LibrarySummaryWithGameStatusResponse extends LibrarySummaryResponse {
  final bool isGamePresent;

  const LibrarySummaryWithGameStatusResponse({
    required int id,
    required int? ownerUserId,
    required String libraryName,
    String? coverUrl,
    required int gameCount,
    required LibraryType libraryType,
    required bool isPrivate,
    int? followerCount,
    bool? isCurrentUserFollowing,
    required this.isGamePresent,
  }) : super(
          id: id,
          ownerUserId: ownerUserId,
          libraryName: libraryName,
          coverUrl: coverUrl,
          gameCount: gameCount,
          libraryType: libraryType,
          isPrivate: isPrivate,
          followerCount: followerCount,
          isCurrentUserFollowing: isCurrentUserFollowing,
        );

  factory LibrarySummaryWithGameStatusResponse.fromJson(Map<String, dynamic> json) {
    // Use the base class factory to parse common fields
    final baseSummary = LibrarySummaryResponse.fromJson(json);
    final isGamePresent = json['gamePresent'] as bool? ?? false;

    return LibrarySummaryWithGameStatusResponse(
      id: baseSummary.id,
      ownerUserId: baseSummary.ownerUserId,
      libraryName: baseSummary.libraryName,
      coverUrl: baseSummary.coverUrl,
      gameCount: baseSummary.gameCount,
      libraryType: baseSummary.libraryType,
      isPrivate: baseSummary.isPrivate,
      followerCount: baseSummary.followerCount,
      isCurrentUserFollowing: baseSummary.isCurrentUserFollowing,
      isGamePresent: isGamePresent,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson(); // Get JSON from base class
    json['gamePresent'] = isGamePresent; // Add the specific field
    return json;
  }

  // Override copyWith to include isPrivate and isGamePresent
  @override
  LibrarySummaryWithGameStatusResponse copyWith({
    int? id,
    int? ownerUserId,
    String? libraryName,
    String? coverUrl,
    int? gameCount,
    LibraryType? libraryType,
    bool? isPrivate,
    int? followerCount,
    bool? isCurrentUserFollowing,
    bool? isGamePresent,
  }) {
    return LibrarySummaryWithGameStatusResponse(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      libraryName: libraryName ?? this.libraryName,
      coverUrl: coverUrl ?? this.coverUrl,
      gameCount: gameCount ?? this.gameCount,
      libraryType: libraryType ?? this.libraryType,
      isPrivate: isPrivate ?? this.isPrivate,
      followerCount: followerCount ?? this.followerCount,
      isCurrentUserFollowing: isCurrentUserFollowing ?? this.isCurrentUserFollowing,
      isGamePresent: isGamePresent ?? this.isGamePresent,
    );
  }
}

// Assuming LibrarySummaryResponse looks something like this:
/*
class LibrarySummaryResponse {
  final int id;
  final String libraryName;
  final String? coverUrl;
  final int gameCount;
  final LibraryType libraryType;

  LibrarySummaryResponse({
    required this.id,
    required this.libraryName,
    this.coverUrl,
    required this.gameCount,
    required this.libraryType,
  });

  // Base toJson using the enum helper
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libraryName': libraryName,
      'coverUrl': coverUrl,
      'gameCount': gameCount,
      'libraryType': libraryType.toJsonString(), 
    };
  }

  // Add fromJson factory if needed
  factory LibrarySummaryResponse.fromJson(Map<String, dynamic> json) {
     final String? coverUrl = json['coverUrl'] as String?;
     final LibraryType libraryType = LibraryType.fromString(json['libraryType'] as String?);
     
     return LibrarySummaryResponse(
       id: json['id'] as int,
       libraryName: json['libraryName'] as String,
       coverUrl: coverUrl,
       gameCount: json['gameCount'] as int? ?? 0, 
       libraryType: libraryType,
     );
  }
}
*/ 