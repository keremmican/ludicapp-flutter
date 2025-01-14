class GameSummary {
  final int id;
  final String? coverUrl;
  final String name;
  final double? rating;
  final String? releaseDate;

  GameSummary({
    required this.id,
    this.coverUrl,
    required this.name,
    this.rating,
    this.releaseDate,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as int,
      coverUrl: json['coverUrl'] as String?,
      name: json['name'] as String,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      releaseDate: json['releaseDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coverUrl': coverUrl,
      'name': name,
      'rating': rating,
      'releaseDate': releaseDate,
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
