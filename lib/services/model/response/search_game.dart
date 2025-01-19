import 'package:ludicapp/services/model/response/game_summary.dart';

class SearchGame {
  final int? id;
  final String name;
  final String? imageUrl;
  final double? weightedScore;

  const SearchGame({
    this.id,
    required this.name,
    this.imageUrl,
    this.weightedScore,
  });

  factory SearchGame.fromJson(Map<String, dynamic> json) {
    return SearchGame(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Unknown',
      imageUrl: json['imageUrl'] as String?,
      weightedScore: json['weightedScore'] as double?,
    );
  }
}

class SearchResponse {
  final List<SearchGame> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final int size;
  final bool last;

  SearchResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
    required this.last,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      content: (json['content'] as List)
          .map((game) => SearchGame.fromJson(game as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
      number: json['number'] as int,
      size: json['size'] as int,
      last: json['last'] as bool,
    );
  }
}

extension SearchGameExtension on SearchGame {
  GameSummary toGameSummary() {
    return GameSummary(
      id: id ?? 0,
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      coverUrl: imageUrl,
      genres: [],
      themes: [],
      platforms: [],
      companies: [],
      screenshots: [],
      websites: {},
    );
  }
} 