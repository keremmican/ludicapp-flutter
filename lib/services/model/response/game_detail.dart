class GameDetail {
  final int id;
  final String coverUrl;
  final String name;
  final String slug;
  final String genre;
  final String releaseFullDate;
  final String gameVideo;
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
    required this.coverUrl,
    required this.name,
    required this.slug,
    required this.genre,
    required this.releaseFullDate,
    required this.gameVideo,
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
    // İç içe listeleri parse et
    final screenshotsList = (json['screenshots'] as List).last as List;
    final platformsList = (json['platforms'] as List).last as List;
    final companiesList = (json['companies'] as List).last as List;
    final themesList = (json['themes'] as List).last as List;
    
    return GameDetail(
      id: json['id'] as int,
      coverUrl: json['coverUrl'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      genre: json['genre'] as String,
      releaseFullDate: json['releaseFullDate'] as String,
      gameVideo: json['gameVideo'] as String,
      summary: json['summary'] as String,
      screenshots: List<String>.from(screenshotsList),
      websites: Map<String, String>.from(json['websites'] as Map)..remove('@class'),
      hastilyGameTime: json['hastilyGameTime'] as int?,
      normallyGameTime: json['normallyGameTime'] as int?,
      completelyGameTime: json['completelyGameTime'] as int?,
      platforms: List<String>.from(platformsList),
      companies: List<String>.from(companiesList),
      themes: List<String>.from(themesList),
      totalRatingScore: json['totalRatingScore'] as double?,
      ageRating: json['ageRating'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coverUrl': coverUrl,
      'name': name,
      'slug': slug,
      'genre': genre,
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
