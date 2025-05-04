import 'package:dio/dio.dart'; // Import DioException
import 'package:flutter/foundation.dart'; // Import foundation for kDebugMode
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/user_game_rating.dart';
import 'package:ludicapp/services/model/request/rating_filter_request.dart';
import 'package:ludicapp/services/model/response/user_game_rating_with_user.dart';
import 'package:ludicapp/services/model/request/user_game_rating_update_request.dart'; // Import new request DTO
import 'package:ludicapp/core/errors/exceptions.dart'; // Import custom exceptions
import 'package:ludicapp/services/model/response/paged_response.dart'; // Import PagedResponse

class RatingRepository {
  final ApiService _apiService = ApiService();

  // --- Unified Update Method ---
  Future<UserGameRating> updateRatingEntry(UserGameRatingUpdateRequest request) async {
    try {
      // GEÇİCİ DEBUG KODU - SORUN ÇÖZÜLDÜĞÜNDE KALDIR
      print('DEBUG - RatingRepository.updateRatingEntry - Request payload: ${request.toJson()}');
      
      final response = await _apiService.post(
        '/api/rating/update',
        request.toJson(),
      );
      
      // GEÇİCİ DEBUG KODU - SORUN ÇÖZÜLDÜĞÜNDE KALDIR
      print('DEBUG - RatingRepository.updateRatingEntry - Response payload: ${response.data}');
      
      // Check response data type *before* attempting parsing
      if (response.data is Map<String, dynamic>) {
        try {
          // Attempt to parse the successful response
          UserGameRating result = UserGameRating.fromJson(response.data);
          
          // GEÇİCİ DEBUG KODU - SORUN ÇÖZÜLDÜĞÜNDE KALDIR
          print('DEBUG - RatingRepository.updateRatingEntry - Parsed result: playStatus=${result.playStatus}, completionStatus=${result.completionStatus}');
          
          return result;
        } on TypeError catch (e, stackTrace) { // Catch specific TypeError during parsing
          print('Error parsing UserGameRating from response data: $e');
          print('Problematic response data: ${response.data}');
          if (kDebugMode) { // Print stack trace only in debug mode
             print('Stack trace: $stackTrace');
          }
          // Throw a more specific exception indicating parsing failure
          throw DataParsingException(
            'Failed to parse successful response from update endpoint. Check logs for problematic data. Error: $e'
          );
        }
      } else {
        // Handle unexpected response data type (not a Map)
        print('Unexpected response data type in updateRatingEntry: ${response.data?.runtimeType}');
        throw DataParsingException('Invalid response format from update endpoint (expected Map<String, dynamic>, got ${response.data?.runtimeType})');
      }
    } on DioException catch (e) {
      // Handle Dio errors (network, 4xx, 5xx)
      throw _handleError(e, 'update rating entry');
    } catch (e) { // Catch any other unexpected errors during the process
      print('Unexpected error during updateRatingEntry: $e');
      // Rethrow a generic exception or a custom one if preferred
      throw Exception('Failed to update rating entry: ${e.toString()}');
    }
  }

  // --- Optional Simple Rate Method (Calls Unified Update) ---
  Future<UserGameRating> rateGame(int gameId, int rating) async {
    final request = UserGameRatingUpdateRequest(gameId: gameId, rating: rating);
    return updateRatingEntry(request); // Delegate to the unified method
  }

  // --- Optional Simple Comment Method (Calls Unified Update) ---
  Future<UserGameRating> commentGame(int gameId, String comment) async {
    final request = UserGameRatingUpdateRequest(gameId: gameId, comment: comment);
    return updateRatingEntry(request); // Delegate to the unified method
  }

  // --- Get Rating Method ---
  Future<UserGameRating?> getRating(int gameId) async {
    try {
      // Backend now uses gameId as RequestParam
      final response = await _apiService.get(
        '/api/rating/get-rating',
        queryParameters: {'gameId': gameId},
      );
      // Check for empty response (might indicate not found, though 404 is expected)
      if (response.data == null) {
        return null;
      }
      if (response.data is Map<String, dynamic>) {
        return UserGameRating.fromJson(response.data);
      } else {
         print('Unexpected response data type in getRating: ${response.data.runtimeType}');
         throw DataParsingException('Invalid response format from get-rating endpoint');
      }
    } on DioException catch (e) {
      // Handle 404 specifically as "not found" -> return null
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e, 'get rating');
    } catch (e) {
      print('Error getting rating: $e');
      throw Exception('Failed to get rating: ${e.toString()}');
    }
  }

  // --- Get All Ratings (Paged) Method ---
  Future<PagedResponse<UserGameRating>> getAllRatings({
    int page = 0,
    int size = 20,
    String sort = 'lastUpdatedDate', // Default sort updated
    String direction = 'DESC',
  }) async {
    try {
      final response = await _apiService.get(
        '/api/rating/get-all-ratings-pageable',
        queryParameters: {
          'page': page,
          'size': size,
          'sort': sort,
          'direction': direction,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return PagedResponse<UserGameRating>.fromJson(
          response.data,
          (json) => UserGameRating.fromJson(json as Map<String, dynamic>),
        );
      } else {
         print('Unexpected response data type in getAllRatings: ${response.data.runtimeType}');
         throw DataParsingException('Invalid response format from get-all-ratings-pageable endpoint');
      }
    } on DioException catch (e) {
      throw _handleError(e, 'get all ratings');
    } catch (e) {
      print('Error getting all ratings: $e');
      throw Exception('Failed to get all ratings: ${e.toString()}');
    }
  }

  // --- Filter Ratings (Paged) Method ---
  Future<PagedResponse<UserGameRating>> filterRatings({
    required RatingFilterRequest filter, 
    int page = 0, 
    int size = 20,
    String sort = 'lastUpdatedDate', // Default sort updated
    String direction = 'DESC',
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
        'direction': direction,
        ...filter.toQueryParameters(), // Use updated method
      };
      
      print('Sending filter request with params: $queryParams');
      
      final response = await _apiService.get(
        '/api/rating/filter',
        queryParameters: queryParams,
      );
      
      print('Filter response data type: ${response.data.runtimeType}');
      print('Filter response data: ${response.data}');
      
      if (response.data is Map<String, dynamic>) {
         return PagedResponse<UserGameRating>.fromJson(
          response.data,
          (json) => UserGameRating.fromJson(json as Map<String, dynamic>),
        );
      } else {
        print('Unexpected response format in filterRatings: ${response.data}');
        throw DataParsingException('Invalid response format from filter endpoint');
      }
    } on DioException catch (e) {
      throw _handleError(e, 'filter ratings');
    } catch (e) {
      print('Error filtering ratings: $e');
      throw Exception('Failed to filter ratings: ${e.toString()}');
    }
  }
  
  // --- Filter Ratings With User (Paged) Method ---
  Future<PagedResponse<UserGameRatingWithUser>> filterRatingsWithUser({
    required RatingFilterRequest filter, 
    int page = 0, 
    int size = 20,
    String sort = 'lastUpdatedDate', // Default sort updated
    String direction = 'DESC',
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
        'direction': direction,
        ...filter.toQueryParameters(), // Use updated method
      };
      
      print('Sending filter-with-user request with params: $queryParams');
      
      final response = await _apiService.get(
        '/api/rating/filter-with-user',
        queryParameters: queryParams,
      );
      
      print('Filter with user response data type: ${response.data.runtimeType}');
      
       if (response.data is Map<String, dynamic>) {
         return PagedResponse<UserGameRatingWithUser>.fromJson(
          response.data,
          (json) => UserGameRatingWithUser.fromJson(json as Map<String, dynamic>),
        );
      } else {
        print('Unexpected response format in filterRatingsWithUser: ${response.data}');
         throw DataParsingException('Invalid response format from filter-with-user endpoint');
      }
    } on DioException catch (e) {
      throw _handleError(e, 'filter ratings with user');
    } catch (e) {
      print('Error filtering ratings with user: $e');
      throw Exception('Failed to filter ratings with user: ${e.toString()}');
    }
  }

  // --- Delete Rating Entry Method ---
  Future<void> deleteRating(int gameId) async {
    try {
      // This endpoint now deletes the entire entry
      await _apiService.delete(
        '/api/rating/rate?gameId=$gameId',
      );
      // No specific return value needed for success (200 OK implies success)
    } on DioException catch (e) {
      throw _handleError(e, 'delete rating');
    } catch (e) {
      print('Error deleting rating: $e');
      throw Exception('Failed to delete rating: ${e.toString()}');
    }
  }

  // --- Delete Comment Method ---
  Future<void> deleteComment(int gameId) async {
    try {
      // This endpoint only removes the comment
      await _apiService.delete(
        '/api/rating/comment?gameId=$gameId',
      );
       // No specific return value needed for success (200 OK implies success)
    } on DioException catch (e) {
      throw _handleError(e, 'delete comment');
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment: ${e.toString()}');
    }
  }

  // --- Private Error Handling Method ---
  Exception _handleError(DioException e, String operation) {
    print('DioException during $operation: ${e.message}');
    if (e.response != null) {
       print('Response status: ${e.response?.statusCode}');
       // Safely handle response data type for error message
       String errorMessage = e.message ?? 'Unknown error';
       if (e.response?.data != null) {
         dynamic responseData = e.response!.data;
         print('Raw Response data: $responseData'); // Log the raw data
         if (responseData is Map && responseData.containsKey('message')) {
           // Standard Spring Boot error format?
           errorMessage = responseData['message']?.toString() ?? errorMessage;
         } else if (responseData is Map && responseData.containsKey('error')) {
             // Another common error format
            errorMessage = responseData['error']?.toString() ?? errorMessage;
         } else if (responseData is String) {
           errorMessage = responseData;
         } else {
           // If it's not a known format or String, just convert the whole thing
           errorMessage = responseData.toString();
         }
       } else {
         print('Response data is null');
       }
       
      if (e.response?.statusCode == 401) {
        return UnauthorizedException('User is not authorized for $operation.');
      }
      if (e.response?.statusCode == 404) {
         return NotFoundException('Resource not found during $operation.');
      }
       // Return more detailed server exception
       return ServerException('Server error during $operation: ${e.response?.statusCode} - $errorMessage');
    }
     if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout) {
        return NetworkException('Network timeout during $operation.');
     }
      if (e.type == DioExceptionType.cancel) {
        return RequestCancelledException('Request cancelled during $operation.');
     }
    // General network or other Dio errors
    return NetworkException('Network error during $operation: ${e.message}');
  }
} 