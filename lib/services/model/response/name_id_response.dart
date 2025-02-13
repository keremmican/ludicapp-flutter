class NameIdResponse {
  final int id;
  final String name;

  NameIdResponse({
    required this.id,
    required this.name,
  });

  factory NameIdResponse.fromJson(Map<String, dynamic> json) {
    return NameIdResponse(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
} 