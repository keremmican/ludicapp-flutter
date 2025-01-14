import 'dart:convert';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/game_detail.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';

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

  Future<GameDetail> fetchGameDetails(int gameId) async {
    final response = await _apiService.get("/games/detail/$gameId");
    
    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return GameDetail.fromJson(jsonData);
  }

  Future<PageableResponse<GameSummary>> fetchGamesByGenre({
    required String genre,
    int page = 0,
    int size = 20,
    bool sortByRating = true,
  }) async {
    final response = await _apiService.get(
      "/games/games-by-genre",
      queryParameters: {
        'genre': genre,
        'page': page.toString(),
        'size': size.toString(),
        'sortByRating': sortByRating.toString(),
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
    required String theme,
    int page = 0,
    int size = 20,
    bool sortByRating = true,
  }) async {
    final response = await _apiService.get(
      "/games/games-by-theme",
      queryParameters: {
        'theme': theme,
        'page': page.toString(),
        'size': size.toString(),
        'sortByRating': sortByRating.toString(),
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
}
