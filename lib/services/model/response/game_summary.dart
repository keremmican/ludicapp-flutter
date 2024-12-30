class GameSummary {
  final int id;
  final String coverUrl;
  final String name;
  final String genre;
  final int releaseYear;

  GameSummary({
    required this.id,
    required this.coverUrl,
    required this.name,
    required this.genre,
    required this.releaseYear,
  });

  // JSON'dan GameSummary nesnesine dönüştürme
  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as int,
      coverUrl: json['coverUrl'] as String,
      name: json['name'] as String,
      genre: json['genre'] as String,
      releaseYear: json['releaseYear'] as int,
    );
  }

  // GameSummary nesnesinden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coverUrl': coverUrl,
      'name': name,
      'genre': genre,
      'releaseYear': releaseYear,
    };
  }
}
