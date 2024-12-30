class GameDetail {
  final int id;
  final String coverUrl;
  final String name;
  final String genre;
  final String releaseFullDate;
  final String? gameVideo;
  final String summary;
  final List<String> screenshots;
  final List<String> websites;
  final int? hastilyGameTime;
  final int? normallyGameTime;
  final int? completelyGameTime;
  final Map<String, String> platforms;
  final String? company;
  final double? totalRatingScore;

  GameDetail({
    required this.id,
    required this.coverUrl,
    required this.name,
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
    this.company,
    this.totalRatingScore,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    return GameDetail(
      id: json['id'],
      coverUrl: json['coverUrl'] ?? '', // Varsayılan değer
      name: json['name'] ?? 'Unknown', // Varsayılan değer
      genre: json['genre'] ?? 'Unknown', // Varsayılan değer
      releaseFullDate: json['releaseFullDate'] ?? 'Unknown Date', // Varsayılan değer
      gameVideo: json['gameVideo'], // Nullable
      summary: json['summary'] ?? 'No summary available.', // Varsayılan değer
      screenshots: List<String>.from(json['screenshots'] ?? []), // Varsayılan değer
      websites: List<String>.from(json['websites'] ?? []), // Varsayılan değer
      hastilyGameTime: json['hastilyGameTime'],
      normallyGameTime: json['normallyGameTime'],
      completelyGameTime: json['completelyGameTime'],
      platforms: Map<String, String>.from(json['platforms'] ?? {}), // Varsayılan değer
      company: json['company'], // Nullable
      totalRatingScore: json['totalRatingScore'], // Nullable
    );
  }
}
