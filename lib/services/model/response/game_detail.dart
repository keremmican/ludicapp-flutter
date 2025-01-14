class GameDetail {
  final int id;
  final String? coverUrl;
  final String name;
  final String slug;
  final List<String> genres;
  final String releaseFullDate;
  final String? gameVideo;
  final String summary;
  final List<String> screenshots;
  final Map<String, String> websites;
  final int? hastilyGameTime;
  final int? normallyGameTime;
  final int? completelyGameTime;
  final List<String> platforms;
  final List<String> companies;
  final List<String> themes;
  final double? totalRatingScore;
  final String? ageRating;

  GameDetail({
    required this.id,
    this.coverUrl,
    required this.name,
    required this.slug,
    required this.genres,
    required this.releaseFullDate,
    this.gameVideo,
    required this.summary,
    required this.screenshots,
    required this.websites,
    this.hastilyGameTime,
    this.normallyGameTime,
    this.completelyGameTime,
    required this.platforms,
    required this.companies,
    required this.themes,
    this.totalRatingScore,
    this.ageRating,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    return GameDetail(
      id: json['id'] as int,
      coverUrl: json['coverUrl'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      genres: List<String>.from(json['genres'] as List),
      releaseFullDate: json['releaseFullDate'] as String,
      gameVideo: json['gameVideo'] as String?,
      summary: json['summary'] as String,
      screenshots: List<String>.from(json['screenshots'] as List),
      websites: Map<String, String>.from(json['websites'] as Map),
      hastilyGameTime: json['hastilyGameTime'] as int?,
      normallyGameTime: json['normallyGameTime'] as int?,
      completelyGameTime: json['completelyGameTime'] as int?,
      platforms: List<String>.from(json['platforms'] as List),
      companies: List<String>.from(json['companies'] as List),
      themes: List<String>.from(json['themes'] as List),
      totalRatingScore: json['totalRatingScore'] != null ? (json['totalRatingScore'] as num).toDouble() : null,
      ageRating: json['ageRating'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coverUrl': coverUrl,
      'name': name,
      'slug': slug,
      'genres': genres,
      'releaseFullDate': releaseFullDate,
      'gameVideo': gameVideo,
      'summary': summary,
      'screenshots': screenshots,
      'websites': websites,
      'hastilyGameTime': hastilyGameTime,
      'normallyGameTime': normallyGameTime,
      'completelyGameTime': completelyGameTime,
      'platforms': platforms,
      'companies': companies,
      'themes': themes,
      'totalRatingScore': totalRatingScore,
      'ageRating': ageRating,
    };
  }
}
