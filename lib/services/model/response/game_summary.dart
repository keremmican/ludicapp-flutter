class GameSummary {
  final int id;
  final String name;
  final String slug;
  final String? coverUrl;
  final String? releaseDate;
  final double? totalRating;
  final int? totalRatingCount;
  final String? summary;
  final List<String> genres;
  final List<String> themes;
  final List<String> platforms;
  final List<String> companies;
  final List<String> screenshots;
  final String? gameVideo;
  final Map<String, String>? websites;
  final int? hastilyGameTime;
  final int? normallyGameTime;
  final int? completelyGameTime;
  final String? pegiAgeRating;
  final String? releaseFullDate;

  GameSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.coverUrl,
    this.releaseDate,
    this.totalRating,
    this.totalRatingCount,
    this.summary,
    required this.genres,
    required this.themes,
    required this.platforms,
    required this.companies,
    required this.screenshots,
    this.gameVideo,
    this.websites,
    this.hastilyGameTime,
    this.normallyGameTime,
    this.completelyGameTime,
    this.pegiAgeRating,
    this.releaseFullDate,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['gameId'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      coverUrl: json['coverUrl'] as String?,
      releaseDate: json['releaseDate'] as String?,
      totalRating: json['totalRating'] != null ? (json['totalRating'] as num).toDouble() : null,
      totalRatingCount: json['totalRatingCount'] as int?,
      summary: json['summary'] as String?,
      genres: List<String>.from(json['genres'] ?? []),
      themes: List<String>.from(json['themes'] ?? []),
      platforms: List<String>.from(json['platforms'] ?? []),
      companies: List<String>.from(json['companies'] ?? []),
      screenshots: List<String>.from(json['screenshots'] ?? []),
      gameVideo: json['gameVideo'] as String?,
      websites: json['websites'] != null 
          ? Map<String, String>.from(json['websites'] as Map)
          : null,
      hastilyGameTime: json['hastilyGameTime'] as int?,
      normallyGameTime: json['normallyGameTime'] as int?,
      completelyGameTime: json['completelyGameTime'] as int?,
      pegiAgeRating: json['pegiAgeRating'] as String?,
      releaseFullDate: json['releaseFullDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': id,
      'name': name,
      'slug': slug,
      'coverUrl': coverUrl,
      'releaseDate': releaseDate,
      'totalRating': totalRating,
      'totalRatingCount': totalRatingCount,
      'summary': summary,
      'genres': genres,
      'themes': themes,
      'platforms': platforms,
      'companies': companies,
      'screenshots': screenshots,
      'gameVideo': gameVideo,
      'websites': websites,
      'hastilyGameTime': hastilyGameTime,
      'normallyGameTime': normallyGameTime,
      'completelyGameTime': completelyGameTime,
      'pegiAgeRating': pegiAgeRating,
      'releaseFullDate': releaseFullDate,
    };
  }
}

class PageableResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final int size;
  final bool first;
  final bool last;
  final bool empty;

  PageableResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageableResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final contentList = json['content'] as List;
    
    return PageableResponse(
      content: contentList
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
      number: json['number'] as int,
      size: json['size'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
      empty: json['empty'] as bool,
    );
  }
}
