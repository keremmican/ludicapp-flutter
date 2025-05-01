import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';
import 'package:ludicapp/services/model/request/rating_filter_request.dart';
import 'package:ludicapp/services/model/response/user_game_rating_with_user.dart';

class RatingRepository {
  final ApiService _apiService = ApiService();

  Future<UserGameRating> rateGame(int gameId, int rating) async {
    try {
      final response = await _apiService.post(
        '/api/rating/rate',
        {
          'gameId': gameId,
          'rating': rating,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        return UserGameRating.fromJson(response.data);
      }
      
      throw Exception('Invalid response format');
    } catch (e) {
      print('Error rating game: $e');
      rethrow;
    }
  }

  Future<UserGameRating> commentGame(int gameId, String comment) async {
    try {
      final response = await _apiService.post(
        '/api/rating/comment',
        {
          'gameId': gameId,
          'comment': comment,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        return UserGameRating.fromJson(response.data);
      } else {
        print('Unexpected response data type in commentGame: ${response.data.runtimeType}');
        throw Exception('Invalid response format from comment endpoint');
      }
    } catch (e) {
      print('Error commenting game: $e');
      rethrow;
    }
  }

  Future<UserGameRating?> getRating(int gameId) async {
    try {
      final response = await _apiService.get('/api/rating/get-rating?gameId=$gameId');
      return UserGameRating.fromJson(response.data);
    } catch (e) {
      print('Error getting rating: $e');
      return null;
    }
  }

  Future<List<UserGameRating>> getAllRatings({int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.get(
        '/api/rating/get-all-ratings-pageable?page=$page&size=$size',
      );
      return (response.data['content'] as List)
          .map((json) => UserGameRating.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all ratings: $e');
      return [];
    }
  }

  Future<List<UserGameRating>> filterRatings({
    required RatingFilterRequest filter, 
    int page = 0, 
    int size = 20,
    String sort = 'ratingDate',
    String direction = 'DESC',
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
        'direction': direction,
        ...filter.toQueryParameters(),
      };
      
      print('Sending filter request with params: $queryParams');
      
      final response = await _apiService.get(
        '/api/rating/filter',
        queryParameters: queryParams,
      );
      
      print('Filter response data type: ${response.data.runtimeType}');
      print('Filter response data: ${response.data}');
      
      // API yanıtının yapısını kontrol et
      if (response.data is Map<String, dynamic> && response.data.containsKey('content')) {
        // Normal sayfalanmış yanıt formatı
        final content = response.data['content'];
        if (content is List) {
          return content.map((json) => UserGameRating.fromJson(json)).toList();
        } else {
          print('Content is not a list: $content');
          return [];
        }
      } else if (response.data is List) {
        // Doğrudan liste formatında yanıt
        return (response.data as List).map((json) => UserGameRating.fromJson(json)).toList();
      } else {
        print('Unexpected response format: ${response.data}');
        return [];
      }
    } catch (e) {
      print('Error filtering ratings: $e');
      return [];
    }
  }
  
  Future<List<UserGameRatingWithUser>> filterRatingsWithUser({
    required RatingFilterRequest filter, 
    int page = 0, 
    int size = 20,
    String sort = 'ratingDate',
    String direction = 'DESC',
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
        'direction': direction,
        ...filter.toQueryParameters(),
      };
      
      print('Sending filter-with-user request with params: $queryParams');
      
      final response = await _apiService.get(
        '/api/rating/filter-with-user',
        queryParameters: queryParams,
      );
      
      print('Filter with user response data type: ${response.data.runtimeType}');
      
      // API yanıtının yapısını kontrol et
      if (response.data is Map<String, dynamic> && response.data.containsKey('content')) {
        // Normal sayfalanmış yanıt formatı
        final content = response.data['content'];
        if (content is List) {
          return content.map((json) => UserGameRatingWithUser.fromJson(json)).toList();
        } else {
          print('Content is not a list: $content');
          return [];
        }
      } else if (response.data is List) {
        // Doğrudan liste formatında yanıt
        return (response.data as List).map((json) => UserGameRatingWithUser.fromJson(json)).toList();
      } else {
        print('Unexpected response format: ${response.data}');
        return [];
      }
    } catch (e) {
      print('Error filtering ratings with user: $e');
      return [];
    }
  }

  Future<bool> deleteRating(int gameId) async {
    try {
      final response = await _apiService.delete('/api/rating/rate?gameId=$gameId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting rating: $e');
      return false;
    }
  }

  Future<bool> deleteComment(int gameId) async {
    try {
      final response = await _apiService.delete('/api/rating/comment?gameId=$gameId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }
} 