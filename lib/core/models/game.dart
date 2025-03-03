import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/user_game_info.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/services/model/response/user_game_actions.dart';

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
  final List<Map<String, dynamic>> gameVideos;
  final Map<String, String>? websites;
  final String? releaseFullDate;
  final Map<String, int>? gameTimeToBeats;
  final String? pegiAgeRating;
  final List<Franchise> franchises;
  final List<GameMode> gameModes;
  final List<PlayerPerspective> playerPerspectives;
  final List<LanguageSupport> languageSupports;
  UserGameActions? _userActions;

  UserGameActions? get userActions => _userActions;
  set userActions(UserGameActions? value) {
    _userActions = value;
  }

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
    UserGameActions? userActions,
  }) {
    _userActions = userActions;
  }

  // Backward compatibility getters
  String? get gameVideo => gameVideos.isNotEmpty ? gameVideos.first['url'] as String? : null;
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
      companies: summary.companies ?? [],
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
      userActions: null,
    );
  }

  factory Game.fromGameDetailWithUserInfo(GameDetailWithUserInfo gameDetail) {
    return Game(
      gameId: gameDetail.gameDetails.id,
      name: gameDetail.gameDetails.name,
      slug: gameDetail.gameDetails.slug,
      coverUrl: gameDetail.gameDetails.coverUrl,
      totalRating: gameDetail.gameDetails.totalRating,
      totalRatingCount: gameDetail.gameDetails.totalRatingCount,
      releaseDate: gameDetail.gameDetails.releaseDate,
      genres: gameDetail.gameDetails.genres,
      themes: gameDetail.gameDetails.themes,
      platforms: gameDetail.gameDetails.platforms,
      companies: gameDetail.gameDetails.companies ?? [],
      screenshots: gameDetail.gameDetails.screenshots,
      summary: gameDetail.gameDetails.summary,
      gameVideos: gameDetail.gameDetails.gameVideos,
      websites: gameDetail.gameDetails.websites,
      gameTimeToBeats: gameDetail.gameDetails.gameTimeToBeats,
      pegiAgeRating: gameDetail.gameDetails.pegiAgeRating,
      franchises: gameDetail.gameDetails.franchises.map((f) => Franchise.fromJson(f)).toList(),
      gameModes: gameDetail.gameDetails.gameModes.map((m) => GameMode.fromJson(m)).toList(),
      playerPerspectives: gameDetail.gameDetails.playerPerspectives.map((p) => PlayerPerspective.fromJson(p)).toList(),
      languageSupports: gameDetail.gameDetails.languageSupports.map((l) => LanguageSupport.fromJson(Map<String, dynamic>.from(l))).toList(),
      userActions: gameDetail.userActions,
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

  Game copyWith({
    int? gameId,
    String? name,
    String? slug,
    String? coverUrl,
    double? totalRating,
    int? totalRatingCount,
    String? releaseDate,
    List<Map<String, dynamic>>? genres,
    List<Map<String, dynamic>>? themes,
    List<Map<String, dynamic>>? platforms,
    List<Map<String, dynamic>>? companies,
    List<String>? screenshots,
    String? summary,
    List<Map<String, dynamic>>? gameVideos,
    Map<String, String>? websites,
    String? releaseFullDate,
    Map<String, int>? gameTimeToBeats,
    String? pegiAgeRating,
    List<Franchise>? franchises,
    List<GameMode>? gameModes,
    List<PlayerPerspective>? playerPerspectives,
    List<LanguageSupport>? languageSupports,
    UserGameActions? userActions,
  }) {
    return Game(
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      coverUrl: coverUrl ?? this.coverUrl,
      totalRating: totalRating ?? this.totalRating,
      totalRatingCount: totalRatingCount ?? this.totalRatingCount,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      themes: themes ?? this.themes,
      platforms: platforms ?? this.platforms,
      companies: companies ?? this.companies,
      screenshots: screenshots ?? this.screenshots,
      summary: summary ?? this.summary,
      gameVideos: gameVideos ?? this.gameVideos,
      websites: websites ?? this.websites,
      releaseFullDate: releaseFullDate ?? this.releaseFullDate,
      gameTimeToBeats: gameTimeToBeats ?? this.gameTimeToBeats,
      pegiAgeRating: pegiAgeRating ?? this.pegiAgeRating,
      franchises: franchises ?? this.franchises,
      gameModes: gameModes ?? this.gameModes,
      playerPerspectives: playerPerspectives ?? this.playerPerspectives,
      languageSupports: languageSupports ?? this.languageSupports,
      userActions: userActions ?? this.userActions,
    );
  }
} 