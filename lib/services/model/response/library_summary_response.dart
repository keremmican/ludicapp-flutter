class LibrarySummaryResponse {
  final int id;
  final String libraryName;
  final String? coverUrl;
  final int gameCount;

  const LibrarySummaryResponse({
    required this.id,
    required this.libraryName,
    this.coverUrl,
    required this.gameCount,
  });

  factory LibrarySummaryResponse.fromJson(Map<String, dynamic> json) {
    return LibrarySummaryResponse(
      id: json['id'] as int,
      libraryName: json['libraryName'] as String,
      coverUrl: json['coverUrl'] as String?,
      gameCount: json['gameCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libraryName': libraryName,
      'coverUrl': coverUrl,
      'gameCount': gameCount,
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
} 