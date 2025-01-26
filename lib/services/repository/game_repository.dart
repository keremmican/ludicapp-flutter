import 'dart:convert';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/game_category.dart';

class GameRepository {
  final ApiService _apiService = ApiService();

  Future<PageableResponse<GameSummary>> fetchNewReleases({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiService.get(
      "/games/new-releases",
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => GameSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PageableResponse<GameSummary>> fetchTopRatedGames({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiService.get(
      "/games/top-games",
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => GameSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<GameSummary> fetchGameDetails(int gameId) async {
    final response = await _apiService.get("/games/detail/$gameId");
    
    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return GameSummary.fromJson(jsonData);
  }

  Future<PageableResponse<GameSummary>> fetchGamesByGenre({
    required int genreId,
    required String sortBy,
    required String sortDirection,
    int page = 0,
    int pageSize = 20,
  }) async {
    final response = await _apiService.get(
      "/games/games-by-genre",
      queryParameters: {
        'genreId': genreId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => GameSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PageableResponse<GameSummary>> fetchGamesByTheme({
    required int themeId,
    required String sortBy,
    required String sortDirection,
    int page = 0,
    int pageSize = 20,
  }) async {
    final response = await _apiService.get(
      "/games/games-by-theme",
      queryParameters: {
        'themeId': themeId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => GameSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PageableResponse<GameSummary>> fetchComingSoon({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiService.get(
      "/games/coming-soon",
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => GameSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<GameCategory>> fetchGenres() async {
    final response = await _apiService.get("/games/get-genres");
    
    final List<dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as List<dynamic>;

    return jsonData.map((json) => GameCategory.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<GameCategory>> fetchThemes() async {
    final response = await _apiService.get("/games/get-themes");
    
    final List<dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as List<dynamic>;

    return jsonData.map((json) => GameCategory.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<GameSummary>> fetchRandomGames({int count = 10}) async {
    final response = await _apiService.get(
      "/games/random",
      queryParameters: {
        'count': count.toString(),
      },
    );

    final List<dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as List<dynamic>;

    return jsonData.map((json) => GameSummary.fromJson(json as Map<String, dynamic>)).toList();
  }
}
