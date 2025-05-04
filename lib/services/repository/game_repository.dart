import 'dart:convert';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/game_category.dart';
import 'package:ludicapp/services/model/response/name_id_response.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';

class GameRepository {
  final ApiService _apiService = ApiService();

  Future<PageableResponse<GameSummary>> fetchNewReleases({
    int page = 0,
    int size = 20,
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      "/games/new-releases",
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
        'availableToPlay': availableToPlay.toString(),
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
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      "/games/top-games",
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
        'availableToPlay': availableToPlay.toString(),
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
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      "/games/games-by-genre",
      queryParameters: {
        'genreId': genreId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
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
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      "/games/games-by-theme",
      queryParameters: {
        'themeId': themeId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
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

  Future<List<GameSummary>> fetchRandomGames({
    int count = 10,
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      "/games/random",
      queryParameters: {
        'count': count.toString(),
        'availableToPlay': availableToPlay.toString(),
      },
    );

    final List<dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as List<dynamic>;

    return jsonData.map((json) => GameSummary.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<NameIdResponse>> getPopularityTypes() async {
    final response = await _apiService.get("/games/get-all-popularity-types");
    
    final List<dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as List<dynamic>;

    return jsonData.map((json) => NameIdResponse.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<GameSummary> getSingleGameByPopularityType(
    int popularityType, {
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      "/games/get-single-game-by-popularity-type",
      queryParameters: {
        'popularityType': popularityType.toString(),
        'availableToPlay': availableToPlay.toString(),
      },
    );
    
    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return GameSummary.fromJson(jsonData);
  }

  Future<PagedGameWithUserResponse> fetchGamesByPopularityType({
    required int popularityType,
    String sortBy = 'rating',
    String sortDirection = 'DESC',
    int page = 0,
    int pageSize = 20,
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      "/games/with-user/get-games-by-popularity-type",
      queryParameters: {
        'popularityType': popularityType.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    final result = PagedGameWithUserResponse.fromJson(jsonData);
    for (var game in result.content) {
      print('Game ID: ${game.gameDetails.id}, UserActions: ${game.userActions}');
    }
    return result;
  }

  Future<PageableResponse<GameSummary>> fetchGamesByPlatform({
    required int platformId,
    required String sortBy,
    required String sortDirection,
    required int page,
    required int pageSize,
    bool availableToPlay = false,
  }) async {
    final response = await _apiService.get(
      '/games/games-by-platform',
      queryParameters: {
        'platformId': platformId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
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

  Future<List<GameSummary>> fetchRandomGamesWithUserInfo({
    bool availableToPlay = false,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      "/games/with-user/random",
      queryParameters: {
        'availableToPlay': availableToPlay.toString(),
        'hideRated': hideRated.toString(),
      },
    );
    
    final List<dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as List<dynamic>;

    return jsonData.map((json) => GameSummary.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<PagedGameWithUserResponse> fetchTopRatedGamesWithUserInfo({
    int page = 0,
    int pageSize = 20,
    bool availableToPlay = false,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      "/games/with-user/top-games",
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
        'hideRated': hideRated.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PagedGameWithUserResponse.fromJson(jsonData);
  }

  Future<PagedGameWithUserResponse> fetchNewReleasesWithUserInfo({
    int page = 0,
    int pageSize = 20,
    bool availableToPlay = false,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      "/games/with-user/new-releases",
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
        'hideRated': hideRated.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PagedGameWithUserResponse.fromJson(jsonData);
  }

  Future<PagedGameWithUserResponse> fetchComingSoonWithUserInfo({
    int page = 0,
    int pageSize = 20,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      "/games/with-user/coming-soon",
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'hideRated': hideRated.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PagedGameWithUserResponse.fromJson(jsonData);
  }

  Future<GameDetailWithUserInfo> fetchGameDetailsWithUserInfo(int gameId) async {
    final response = await _apiService.get("/games/with-user/detail/$gameId");
    
    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return GameDetailWithUserInfo.fromJson(jsonData);
  }

  /// Saves a game for the current user
  /// 
  /// [gameId] The ID of the game to save
  /// Returns true if the operation was successful
  Future<bool> saveGame(int gameId) async {
    try {
      final response = await _apiService.post(
        "/games/$gameId/save",
        {},
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }

  /// Removes a game from the user's saved games
  /// 
  /// [gameId] The ID of the game to unsave
  /// Returns true if the operation was successful
  Future<bool> unsaveGame(int gameId) async {
    try {
      final response = await _apiService.delete(
        "/games/$gameId/save",
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unsaving game: $e');
      return false;
    }
  }

  Future<PagedGameWithUserResponse> fetchGamesByPopularityTypeWithUserInfo({
    required int popularityType,
    String sortBy = 'rating',
    String sortDirection = 'DESC',
    int page = 0,
    int pageSize = 20,
    bool availableToPlay = false,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      "/games/with-user/get-games-by-popularity-type",
      queryParameters: {
        'popularityType': popularityType.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
        'hideRated': hideRated.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PagedGameWithUserResponse.fromJson(jsonData);
  }

  Future<GameDetailWithUserInfo> getSingleGameByPopularityTypeWithUserInfo(
    int popularityType, {
    bool hideRated = false,
  }) async {
    try {
      final response = await _apiService.get(
        '/games/with-user/get-single-game-by-popularity-type',
        queryParameters: {
          'popularityType': popularityType.toString(),
          'hideRated': hideRated.toString(),
        },
      );
      
      final Map<String, dynamic> jsonData = response.data is String 
          ? json.decode(response.data as String)
          : response.data as Map<String, dynamic>;

      return GameDetailWithUserInfo.fromJson(jsonData);
    } catch (e) {
      print('Error fetching single game by popularity type with user info: $e');
      rethrow;
    }
  }

  Future<PagedGameWithUserResponse> fetchGamesByPlatformWithUserInfo({
    required int platformId,
    required String sortBy,
    required String sortDirection,
    required int page,
    required int pageSize,
    bool availableToPlay = false,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      '/games/with-user/games-by-platform',
      queryParameters: {
        'platformId': platformId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
        'hideRated': hideRated.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PagedGameWithUserResponse.fromJson(jsonData);
  }

  Future<PagedGameWithUserResponse> fetchGamesByGenreWithUserInfo({
    required int genreId,
    required String sortBy,
    required String sortDirection,
    int page = 0,
    int pageSize = 20,
    bool availableToPlay = false,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      '/games/with-user/games-by-genre',
      queryParameters: {
        'genreId': genreId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
        'hideRated': hideRated.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PagedGameWithUserResponse.fromJson(jsonData);
  }

  Future<PagedGameWithUserResponse> fetchGamesByThemeWithUserInfo({
    required int themeId,
    required String sortBy,
    required String sortDirection,
    int page = 0,
    int pageSize = 20,
    bool availableToPlay = false,
    bool hideRated = false,
  }) async {
    final response = await _apiService.get(
      '/games/with-user/games-by-theme',
      queryParameters: {
        'themeId': themeId.toString(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'availableToPlay': availableToPlay.toString(),
        'hideRated': hideRated.toString(),
      },
    );

    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PagedGameWithUserResponse.fromJson(jsonData);
  }
}
