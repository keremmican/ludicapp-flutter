import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';

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
        final data = Map<String, dynamic>.from(response.data);
        // Parse ratingDate from the response
        if (data['ratingDate'] != null) {
          if (data['ratingDate'] is List) {
            // Handle List format: [2024, 3, 3, 23, 25, 10, 251483000]
            final List<dynamic> dateList = data['ratingDate'] as List;
            final year = dateList[0] as int;
            final month = dateList[1] as int;
            final day = dateList[2] as int;
            final hour = dateList[3] as int;
            final minute = dateList[4] as int;
            final second = dateList[5] as int;
            final microsecond = (dateList[6] as int) ~/ 1000; // Convert nanoseconds to microseconds
            
            final dateTime = DateTime(year, month, day, hour, minute, second, microsecond);
            data['ratingDate'] = dateTime.toIso8601String();
          }
        }
        return UserGameRating.fromJson(data);
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
      
      // Yanıt formatını kontrol et ve ratingDate'i dönüştür (rateGame'deki gibi)
      if (response.data is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(response.data);
        // Parse ratingDate from the response
        if (data['ratingDate'] != null) {
          if (data['ratingDate'] is List) {
            // Handle List format: [2024, 3, 3, 23, 25, 10, 251483000]
            try {
              final List<dynamic> dateList = data['ratingDate'] as List;
              final year = dateList[0] as int;
              final month = dateList[1] as int;
              final day = dateList[2] as int;
              final hour = dateList[3] as int;
              final minute = dateList[4] as int;
              final second = dateList[5] as int;
              // Nanoseconds'ı microseconds'a çevirirken null veya hatalı tip kontrolü
              final nanoseconds = dateList.length > 6 ? dateList[6] : 0;
              final microsecond = (nanoseconds is int) ? nanoseconds ~/ 1000 : 0;
              
              final dateTime = DateTime.utc(year, month, day, hour, minute, second, microsecond);
              data['ratingDate'] = dateTime.toIso8601String();
            } catch (e) {
              print('Error parsing ratingDate list in commentGame: $e');
              // Hata durumunda tarihi null veya varsayılan bir değere ayarlayabiliriz
              // Veya hatayı yukarı fırlatabiliriz. Şimdilik loglayıp devam edelim.
              // Belki de tarihi olmayan bir UserGameRating döndürmek daha iyi?
              // Şimdilik fromJson'a gitmesine izin verelim, orada hata verebilir.
            }
          } else if (data['ratingDate'] is String) {
            // Eğer zaten string ise bir şey yapma
          } else {
            // Beklenmeyen format
            print('Unexpected format for ratingDate in commentGame: ${data['ratingDate'].runtimeType}');
            // Hata yönetimi eklenebilir
          }
        }
        return UserGameRating.fromJson(data);
      } else {
        // Yanıt Map değilse
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