// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameSummary _$GameSummaryFromJson(Map<String, dynamic> json) => GameSummary(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      coverUrl: json['coverUrl'] as String?,
      releaseDate: json['releaseDate'] as String?,
      totalRating: (json['totalRating'] as num?)?.toDouble(),
      totalRatingCount: (json['totalRatingCount'] as num?)?.toInt(),
      description: json['description'] as String?,
      summary: json['summary'] as String?,
      genres: (json['genres'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      themes: (json['themes'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      platforms: (json['platforms'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      companies: (json['companies'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      screenshots: (json['screenshots'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      gameVideos: (json['gameVideos'] as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      websites: (json['websites'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      gameTimeToBeats: (json['gameTimeToBeats'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      pegiAgeRating: json['pegiAgeRating'] as String?,
      franchises: (json['franchises'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      gameModes: (json['gameModes'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      playerPerspectives: (json['playerPerspectives'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      languageSupports: (json['languageSupports'] as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
    );

Map<String, dynamic> _$GameSummaryToJson(GameSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'coverUrl': instance.coverUrl,
      'releaseDate': instance.releaseDate,
      'totalRating': instance.totalRating,
      'totalRatingCount': instance.totalRatingCount,
      'description': instance.description,
      'summary': instance.summary,
      'genres': instance.genres,
      'themes': instance.themes,
      'platforms': instance.platforms,
      'companies': instance.companies,
      'screenshots': instance.screenshots,
      'gameVideos': instance.gameVideos,
      'websites': instance.websites,
      'gameTimeToBeats': instance.gameTimeToBeats,
      'pegiAgeRating': instance.pegiAgeRating,
      'franchises': instance.franchises,
      'gameModes': instance.gameModes,
      'playerPerspectives': instance.playerPerspectives,
      'languageSupports': instance.languageSupports,
    };
