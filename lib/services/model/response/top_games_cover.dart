class TopRatedGamesCover {
  final int id;
  final String coverUrl;

  TopRatedGamesCover({
    required this.id,
    required this.coverUrl
  });

  // JSON'dan GameSummary nesnesine dönüştürme
  factory TopRatedGamesCover.fromJson(Map<String, dynamic> json) {
    return TopRatedGamesCover(
      id: json['id'] as int,
      coverUrl: json['coverUrl'] as String,
    );
  }

  // GameSummary nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coverUrl': coverUrl
    };
  }
}
