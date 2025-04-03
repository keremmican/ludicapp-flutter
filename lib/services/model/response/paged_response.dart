// Generic Paged Response Model

class PagedResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final int number; // Current page number (0-indexed)
  final int size;
  final bool first;
  final bool last;
  final bool empty;

  PagedResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResponse<T>(
      content: (json['content'] as List?)
          ?.map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList() ?? [],
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      empty: json['empty'] as bool? ?? true,
    );
  }

  // Optional: Add toJson if needed, requires T to have toJson()
  /*
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'content': content.map(toJsonT).toList(),
      'totalPages': totalPages,
      'totalElements': totalElements,
      'number': number,
      'size': size,
      'first': first,
      'last': last,
      'empty': empty,
    };
  }
  */
} 