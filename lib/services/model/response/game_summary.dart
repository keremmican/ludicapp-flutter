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

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as int,
      coverUrl: json['coverUrl'] as String,
      name: json['name'] as String,
      genre: json['genre'] as String,
      releaseYear: json['releaseYear'] as int,
    );
  }

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
    final contentList = (json['content'] as List).last as List;
    
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
