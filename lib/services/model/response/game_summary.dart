class GameSummary {
  final int id;
  final String name;
  final String slug;
  final String? coverUrl;
  final String? releaseDate;
  final double? totalRating;
  final int? totalRatingCount;
  final String? summary;
  final List<Map<String, dynamic>> genres;
  final List<Map<String, dynamic>> themes;
  final List<Map<String, dynamic>> platforms;
  final List<Map<String, dynamic>> companies;
  final List<String> screenshots;
  final List<Map<String, dynamic>> gameVideos;
  final Map<String, String>? websites;
  final Map<String, int>? gameTimeToBeats;
  final String? pegiAgeRating;
  final List<Map<String, dynamic>> franchises;
  final List<Map<String, dynamic>> gameModes;
  final List<Map<String, dynamic>> playerPerspectives;
  final List<Map<String, String>> languageSupports;

  GameSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.coverUrl,
    this.releaseDate,
    this.totalRating,
    this.totalRatingCount,
    this.summary,
    required this.genres,
    required this.themes,
    required this.platforms,
    required this.companies,
    required this.screenshots,
    required this.gameVideos,
    this.websites,
    this.gameTimeToBeats,
    this.pegiAgeRating,
    required this.franchises,
    required this.gameModes,
    required this.playerPerspectives,
    required this.languageSupports,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    try {
      // Handle websites conversion
      Map<String, String>? websitesMap;
      if (json['websites'] != null) {
        try {
          websitesMap = Map<String, String>.from(json['websites'] as Map);
        } catch (e) {
          print('Error converting websites: $e');
          websitesMap = null;
        }
      }

      // Handle game time to beats conversion
      Map<String, int>? gameTimeToBeatsMap;
      if (json['gameTimeToBeats'] != null) {
        try {
          gameTimeToBeatsMap = (json['gameTimeToBeats'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value is int ? value : (value as num?)?.toInt() ?? 0
            ),
          );
        } catch (e) {
          print('Error converting gameTimeToBeats: $e');
          gameTimeToBeatsMap = null;
        }
      }

      // Convert lists with safe null checks and type casting
      List<Map<String, dynamic>> convertList(dynamic list) {
        if (list == null) return [];
        return (list as List).map((e) => e as Map<String, dynamic>).toList();
      }

      List<Map<String, String>> convertStringMapList(dynamic list) {
        if (list == null) return [];
        return (list as List).map((e) {
          Map<String, dynamic> map = e as Map<String, dynamic>;
          return map.map((key, value) => MapEntry(
            key,
            value?.toString() ?? ''
          ));
        }).toList();
      }

      // Check both 'id' and 'gameId' fields for backward compatibility
      final gameId = json['gameId'] ?? json['id'];
      
      return GameSummary(
        id: gameId != null 
            ? (gameId is int 
                ? gameId 
                : (gameId as num).toInt()) 
            : 0,
        name: json['name'] as String? ?? 'Unknown Game',
        slug: json['slug'] as String? ?? 'unknown-game',
        coverUrl: json['coverUrl'] as String?,
        releaseDate: json['releaseDate'] as String?,
        totalRating: json['totalRating'] != null 
            ? (json['totalRating'] is double 
                ? json['totalRating'] 
                : (json['totalRating'] as num).toDouble()) 
            : null,
        totalRatingCount: json['totalRatingCount'] != null 
            ? (json['totalRatingCount'] is int 
                ? json['totalRatingCount'] 
                : (json['totalRatingCount'] as num).toInt()) 
            : null,
        summary: json['summary'] as String?,
        genres: convertList(json['genres']),
        themes: convertList(json['themes']),
        platforms: convertList(json['platforms']),
        companies: convertList(json['companies']),
        screenshots: List<String>.from(json['screenshots'] ?? []),
        gameVideos: convertStringMapList(json['gameVideos']),
        websites: websitesMap,
        gameTimeToBeats: gameTimeToBeatsMap,
        pegiAgeRating: json['pegiAgeRating'] as String?,
        franchises: convertList(json['franchises']),
        gameModes: convertList(json['gameModes']),
        playerPerspectives: convertList(json['playerPerspectives']),
        languageSupports: convertStringMapList(json['languageSupports']),
      );
    } catch (e, stackTrace) {
      print('Error in GameSummary.fromJson: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': id,  // Keep this as 'gameId' since API expects it
      'name': name,
      'slug': slug,
      'coverUrl': coverUrl,
      'releaseDate': releaseDate,
      'totalRating': totalRating,
      'totalRatingCount': totalRatingCount,
      'summary': summary,
      'genres': genres,
      'themes': themes,
      'platforms': platforms,
      'companies': companies,
      'screenshots': screenshots,
      'gameVideos': gameVideos,
      'websites': websites,
      'gameTimeToBeats': gameTimeToBeats,
      'pegiAgeRating': pegiAgeRating,
      'franchises': franchises,
      'gameModes': gameModes,
      'playerPerspectives': playerPerspectives,
      'languageSupports': languageSupports,
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
    return PageableResponse<T>(
      content: (json['content'] as List?)
          ?.map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList() ?? [],
      totalPages: json['totalPages'] != null ? (json['totalPages'] is int ? json['totalPages'] : (json['totalPages'] as num).toInt()) : 0,
      totalElements: json['totalElements'] != null ? (json['totalElements'] is int ? json['totalElements'] : (json['totalElements'] as num).toInt()) : 0,
      number: json['number'] != null ? (json['number'] is int ? json['number'] : (json['number'] as num).toInt()) : 0,
      size: json['size'] != null ? (json['size'] is int ? json['size'] : (json['size'] as num).toInt()) : 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      empty: json['empty'] as bool? ?? true,
    );
  }
}
