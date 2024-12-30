class GameDetail {
  final int id;
  final String coverUrl;
  final String name;
  final String slug;
  final String genre;
  final String releaseFullDate;
  final String? gameVideo;
  final String summary;
  final List<String> screenshots;
  final Map<String, String> websites;
  final int? hastilyGameTime;
  final int? normallyGameTime;
  final int? completelyGameTime;
  final List<String> platforms;
  final List<String>? companies;
  final double? totalRatingScore;
  final String? ageRating;
  final List<String> tags;

  GameDetail({
    required this.id,
    required this.coverUrl,
    required this.name,
    required this.slug,
    required this.genre,
    required this.releaseFullDate,
    this.gameVideo,
    required this.summary,
    required this.screenshots,
    required this.websites,
    this.hastilyGameTime,
    this.normallyGameTime,
    this.completelyGameTime,
    required this.platforms,
    this.companies,
    this.totalRatingScore,
    this.ageRating,
    this.tags = const [],
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    return GameDetail(
      id: json['id'],
      coverUrl: json['coverUrl'] ?? '',
      name: json['name'] ?? 'Unknown',
      slug: json['slug'] ?? '',
      genre: json['genre'] ?? 'Unknown',
      releaseFullDate: json['releaseFullDate'] ?? 'Unknown Date',
      gameVideo: json['gameVideo'],
      summary: json['summary'] ?? 'No summary available.',
      screenshots: List<String>.from(json['screenshots'] ?? []),
      websites: Map<String, String>.from(json['websites'] ?? {}),
      hastilyGameTime: json['hastilyGameTime'],
      normallyGameTime: json['normallyGameTime'],
      completelyGameTime: json['completelyGameTime'],
      platforms: List<String>.from(json['platforms'] ?? []),
      companies: json['companies'] != null ? List<String>.from(json['companies']) : null,
      totalRatingScore: json['totalRatingScore']?.toDouble(),
      ageRating: json['ageRating'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }
}
