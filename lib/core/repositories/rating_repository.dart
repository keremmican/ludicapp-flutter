import 'package:dio/dio.dart';
import '../models/user_game_rating.dart';
import '../services/api_service.dart';

class RatingRepository {
  final ApiService _apiService;

  RatingRepository(this._apiService);

  Future<UserGameRating> rateGame(int gameId, int rating) async {
    try {
      final response = await _apiService.post(
        '/api/rating/rate',
        data: {
          'gameId': gameId,
          'rating': rating,
        },
      );
      return UserGameRating.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserGameRating> commentGame(int gameId, String comment) async {
    try {
      final response = await _apiService.post(
        '/api/rating/comment',
        data: {
          'gameId': gameId,
          'comment': comment,
        },
      );
      return UserGameRating.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserGameRating?> getRating(int gameId) async {
    try {
      final response = await _apiService.get(
        '/api/rating/get-rating',
        queryParameters: {'gameId': gameId},
      );
      return UserGameRating.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  Future<List<UserGameRating>> getAllRatings({int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.get(
        '/api/rating/get-all-ratings-pageable',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      return (response.data['content'] as List)
          .map((json) => UserGameRating.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRating(int gameId) async {
    try {
      await _apiService.delete(
        '/api/rating/rate',
        queryParameters: {'gameId': gameId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteComment(int gameId) async {
    try {
      await _apiService.delete(
        '/api/rating/comment',
        queryParameters: {'gameId': gameId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return UnauthorizedException();
    }
    return Exception('Failed to perform rating operation: ${e.message}');
  }
}

class UnauthorizedException implements Exception {
  final String message = 'User is not authorized';
} 