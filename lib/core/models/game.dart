import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';

class GameMode {
  final int id;
  final String name;

  GameMode({required this.id, required this.name});

  factory GameMode.fromJson(Map<String, dynamic> json) {
    return GameMode(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class Franchise {
  final int id;
  final String name;

  Franchise({required this.id, required this.name});

  factory Franchise.fromJson(Map<String, dynamic> json) {
    return Franchise(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class PlayerPerspective {
  final int id;
  final String name;

  PlayerPerspective({required this.id, required this.name});

  factory PlayerPerspective.fromJson(Map<String, dynamic> json) {
    return PlayerPerspective(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class LanguageSupport {
  final String language;
  final String type;

  LanguageSupport({required this.language, required this.type});

  factory LanguageSupport.fromJson(Map<String, dynamic> json) {
    return LanguageSupport(
      language: json['language'] as String,
      type: json['type'] as String,
    );
  }
}

class Game {
  static final Map<String, List<Image>> _screenshotCache = {};

  final int gameId;
  final String name;
  final String slug;
  final String? coverUrl;
  final double? totalRating;
  final int? totalRatingCount;
  final String? releaseDate;
  final List<Map<String, dynamic>> genres;
  final List<Map<String, dynamic>> themes;
  final List<Map<String, dynamic>> platforms;
  final List<Map<String, dynamic>> companies;
  final List<String> screenshots;
  final String? summary;
  final List<Map<String, String>> gameVideos;
  final Map<String, String>? websites;
  final String? releaseFullDate;
  final Map<String, int>? gameTimeToBeats;
  final String? pegiAgeRating;
  final List<Franchise> franchises;
  final List<GameMode> gameModes;
  final List<PlayerPerspective> playerPerspectives;
  final List<LanguageSupport> languageSupports;

  Game({
    required this.gameId,
    required this.name,
    required this.slug,
    this.coverUrl,
    this.totalRating,
    this.totalRatingCount,
    this.releaseDate,
    required this.genres,
    required this.themes,
    required this.platforms,
    required this.companies,
    required this.screenshots,
    this.summary,
    required this.gameVideos,
    this.websites,
    this.releaseFullDate,
    this.gameTimeToBeats,
    this.pegiAgeRating,
    required this.franchises,
    required this.gameModes,
    required this.playerPerspectives,
    required this.languageSupports,
  });

  // Backward compatibility getters
  String? get gameVideo => gameVideos.isNotEmpty ? gameVideos.first['url'] : null;
  int? get hastilyGameTime => gameTimeToBeats?['hastily'];
  int? get normallyGameTime => gameTimeToBeats?['normally'];
  int? get completelyGameTime => gameTimeToBeats?['completely'];

  String getGenreName(Map<String, dynamic> genre) => genre['name'] as String;
  String getThemeName(Map<String, dynamic> theme) => theme['name'] as String;
  String getPlatformName(Map<String, dynamic> platform) => platform['name'] as String;
  String getCompanyName(Map<String, dynamic> company) => company['name'] as String;

  factory Game.fromGameSummary(GameSummary summary) {
    return Game(
      gameId: summary.id,
      name: summary.name,
      slug: summary.slug,
      coverUrl: summary.coverUrl,
      totalRating: summary.totalRating,
      totalRatingCount: summary.totalRatingCount,
      releaseDate: summary.releaseDate,
      genres: summary.genres,
      themes: summary.themes,
      platforms: summary.platforms,
      companies: summary.companies,
      screenshots: summary.screenshots,
      summary: summary.summary,
      gameVideos: summary.gameVideos,
      websites: summary.websites,
      gameTimeToBeats: summary.gameTimeToBeats,
      pegiAgeRating: summary.pegiAgeRating,
      franchises: summary.franchises.map((f) => Franchise.fromJson(f)).toList(),
      gameModes: summary.gameModes.map((m) => GameMode.fromJson(m)).toList(),
      playerPerspectives: summary.playerPerspectives.map((p) => PlayerPerspective.fromJson(p)).toList(),
      languageSupports: summary.languageSupports.map((l) => LanguageSupport.fromJson(Map<String, dynamic>.from(l))).toList(),
    );
  }

  static void preloadScreenshots(int gameId, List<String> screenshots) {
    final cacheKey = gameId.toString();
    if (!_screenshotCache.containsKey(cacheKey)) {
      _screenshotCache[cacheKey] = screenshots.map((url) => Image.network(url)).toList();
    }
  }

  static List<Image>? getPreloadedScreenshots(int gameId) {
    return _screenshotCache[gameId.toString()];
  }

  static void clearCache() {
    _screenshotCache.clear();
  }
} 