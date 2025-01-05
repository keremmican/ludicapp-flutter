import 'dart:convert';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/game_detail.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/top_games_cover.dart';

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

    print('Response data type: ${response.data.runtimeType}');
    print('Response data: ${response.data}');

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => GameSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PageableResponse<TopRatedGamesCover>> fetchTopRatedGames({
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

    print('Response data type: ${response.data.runtimeType}');
    print('Response data: ${response.data}');

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => TopRatedGamesCover.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<GameDetail> fetchGameDetails(int gameId) async {
    final response = await _apiService.get("/games/detail/$gameId");
    
    print('Response data type: ${response.data.runtimeType}');
    print('Response data: ${response.data}');

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return GameDetail.fromJson(jsonData);
  }

  Future<PageableResponse<TopRatedGamesCover>> fetchGamesByGenre({
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

    return PageableResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TopRatedGamesCover.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PageableResponse<TopRatedGamesCover>> fetchGamesByTheme({
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

    return PageableResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TopRatedGamesCover.fromJson(json as Map<String, dynamic>),
    );
  }
}
