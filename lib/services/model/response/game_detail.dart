import 'package:ludicapp/services/model/response/game_summary.dart';

class GameDetail {
  final int id;
  final String? coverUrl;
  final String name;
  final String slug;
  final List<Map<String, dynamic>> genres;
  final String releaseFullDate;
  final List<Map<String, String>> gameVideos;
  final String summary;
  final List<String> screenshots;
  final Map<String, String> websites;
  final Map<String, int>? gameTimeToBeats;
  final List<Map<String, dynamic>> platforms;
  final List<Map<String, dynamic>> companies;
  final List<Map<String, dynamic>> themes;
  final double? totalRatingScore;
  final String? ageRating;
  final List<Map<String, dynamic>> franchises;
  final List<Map<String, dynamic>> gameModes;
  final List<Map<String, dynamic>> playerPerspectives;
  final List<Map<String, String>> languageSupports;

  GameDetail({
    required this.id,
    this.coverUrl,
    required this.name,
    required this.slug,
    required this.genres,
    required this.releaseFullDate,
    required this.gameVideos,
    required this.summary,
    required this.screenshots,
    required this.websites,
    this.gameTimeToBeats,
    required this.platforms,
    required this.companies,
    required this.themes,
    this.totalRatingScore,
    this.ageRating,
    required this.franchises,
    required this.gameModes,
    required this.playerPerspectives,
    required this.languageSupports,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    return GameDetail(
      id: json['id'] != null ? json['id'] as int : 0,
      coverUrl: json['coverUrl'] as String?,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      genres: (json['genres'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      releaseFullDate: json['releaseFullDate'] as String? ?? '',
      gameVideos: (json['gameVideos'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      summary: json['summary'] as String? ?? '',
      screenshots: List<String>.from(json['screenshots'] as List? ?? []),
      websites: Map<String, String>.from(json['websites'] as Map? ?? {}),
      gameTimeToBeats: json['gameTimeToBeats'] != null 
          ? (json['gameTimeToBeats'] as Map?)?.map(
              (key, value) => MapEntry(
                key.toString(),
                value is int ? value : (value as num?)?.toInt() ?? 0
              ),
            )
          : null,
      platforms: (json['platforms'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      companies: (json['companies'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      themes: (json['themes'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      totalRatingScore: json['totalRatingScore'] != null ? (json['totalRatingScore'] as num).toDouble() : null,
      ageRating: json['ageRating'] as String?,
      franchises: (json['franchises'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      gameModes: (json['gameModes'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      playerPerspectives: (json['playerPerspectives'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      languageSupports: (json['languageSupports'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coverUrl': coverUrl,
      'name': name,
      'slug': slug,
      'genres': genres,
      'releaseFullDate': releaseFullDate,
      'gameVideos': gameVideos,
      'summary': summary,
      'screenshots': screenshots,
      'websites': websites,
      'gameTimeToBeats': gameTimeToBeats,
      'platforms': platforms,
      'companies': companies,
      'themes': themes,
      'totalRatingScore': totalRatingScore,
      'ageRating': ageRating,
      'franchises': franchises,
      'gameModes': gameModes,
      'playerPerspectives': playerPerspectives,
      'languageSupports': languageSupports,
    };
  }

  GameSummary toGameSummary() {
    return GameSummary(
      id: id,
      name: name,
      slug: slug,
      coverUrl: coverUrl,
      releaseDate: releaseFullDate,
      totalRating: totalRatingScore,
      summary: summary,
      genres: genres,
      themes: themes,
      platforms: platforms,
      companies: companies,
      screenshots: screenshots,
      gameVideos: gameVideos,
      websites: websites,
      gameTimeToBeats: gameTimeToBeats,
      pegiAgeRating: ageRating,
      releaseFullDate: releaseFullDate,
      franchises: franchises,
      gameModes: gameModes,
      playerPerspectives: playerPerspectives,
      languageSupports: languageSupports,
    );
  }
}
