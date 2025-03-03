import 'package:dio/dio.dart';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';

class LibraryRepository {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<bool> saveGame(int gameId) async {
    try {
      final response = await _apiService.post(
        '/api/library/save-game?gameId=$gameId',
        {},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error saving game: ${e.message}');
      return false;
    }
  }

  Future<bool> unsaveGame(int gameId) async {
    try {
      final response = await _apiService.post(
        '/api/library/unsave-game?gameId=$gameId',
        {},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Error unsaving game: ${e.message}');
      return false;
    }
  }

  Future<List<LibrarySummaryResponse>> getAllLibrarySummaries({String? userId}) async {
    try {
      String? finalUserId = userId;
      if (finalUserId == null) {
        finalUserId = await _storage.read(key: 'userId');
        if (finalUserId == null) {
          throw Exception('User ID not found');
        }
      }

      final response = await _apiService.get('/api/library/summary/all?userId=$finalUserId');
      
      if (response.data is List) {
        return (response.data as List)
          .map((json) => LibrarySummaryResponse.fromJson(json))
          .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting library summaries: $e');
      return [];
    }
  }

  Future<PagedGameWithUserResponse> getGamesByLibraryId(
    int libraryId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/library/$libraryId/games',
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
        },
      );
      
      return PagedGameWithUserResponse.fromJson(response.data);
    } catch (e) {
      print('Error getting games by library ID: $e');
      return PagedGameWithUserResponse(content: []);
    }
  }
} 