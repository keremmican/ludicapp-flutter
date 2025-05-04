// Generic Paged Response Model

class PagedResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool last;
  final bool first;
  final bool empty;

  PagedResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.last,
    required this.first,
    required this.empty,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final contentList = json['content'] as List? ?? [];
    return PagedResponse<T>(
      content: contentList.map(fromJsonT).toList(),
      pageNumber: json['pageable']?['pageNumber'] ?? json['number'] ?? 0,
      pageSize: json['pageable']?['pageSize'] ?? json['size'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      last: json['last'] ?? false,
      first: json['first'] ?? false,
      empty: json['empty'] ?? false,
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