class GameCategory {
  final int id;
  final String name;
  final String? slug;
  final String? url;

  const GameCategory({
    required this.id,
    required this.name,
    this.slug,
    this.url,
  });

  factory GameCategory.fromJson(Map<String, dynamic> json) => GameCategory(
    id: json['id'] as int,
    name: json['name'] as String,
    slug: json['slug'] as String?,
    url: json['url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'url': url,
  };
} 