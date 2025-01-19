import 'package:flutter/material.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';

class Game {
  static final Map<String, List<Image>> _screenshotCache = {};

  final int gameId;
  final String name;
  final String slug;
  final String? coverUrl;
  final double? totalRating;
  final String? releaseDate;
  final List<String> genres;
  final List<String> themes;
  final List<String> platforms;
  final List<String> companies;
  final List<String> screenshots;
  final String? summary;
  final String? gameVideo;
  final Map<String, String>? websites;
  final String? releaseFullDate;
  final int? hastilyGameTime;
  final int? normallyGameTime;
  final int? completelyGameTime;
  final String? pegiAgeRating;

  Game({
    required this.gameId,
    required this.name,
    required this.slug,
    this.coverUrl,
    this.totalRating,
    this.releaseDate,
    required this.genres,
    required this.themes,
    required this.platforms,
    required this.companies,
    required this.screenshots,
    this.summary,
    this.gameVideo,
    this.websites,
    this.releaseFullDate,
    this.hastilyGameTime,
    this.normallyGameTime,
    this.completelyGameTime,
    this.pegiAgeRating,
  });

  factory Game.fromGameSummary(GameSummary summary) {
    return Game(
      gameId: summary.id,
      name: summary.name,
      slug: summary.slug,
      coverUrl: summary.coverUrl,
      totalRating: summary.totalRating,
      releaseDate: summary.releaseDate,
      genres: summary.genres,
      themes: summary.themes,
      platforms: summary.platforms,
      companies: summary.companies,
      screenshots: summary.screenshots?.map((url) => url.toString()).toList() ?? [],
      summary: summary.summary,
      gameVideo: summary.gameVideo,
      websites: summary.websites,
      releaseFullDate: summary.releaseFullDate,
      hastilyGameTime: summary.hastilyGameTime,
      normallyGameTime: summary.normallyGameTime,
      completelyGameTime: summary.completelyGameTime,
      pegiAgeRating: summary.pegiAgeRating,
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