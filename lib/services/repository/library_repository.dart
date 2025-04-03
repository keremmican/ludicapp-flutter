import 'package:dio/dio.dart';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/user_game_library.dart';
import 'package:ludicapp/services/model/response/custom_library_status_response.dart';
import 'package:ludicapp/services/model/response/library_summary_with_game_status_response.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/services/model/response/user_follower_response.dart';
import 'package:ludicapp/services/model/response/paged_response.dart';
import 'package:ludicapp/services/token_service.dart';

class LibraryRepository {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final TokenService _tokenService = TokenService();

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

      final response = await _apiService.get(
        '/api/library/summary/all', 
        queryParameters: {
          'userId': finalUserId,
        }
      );
      
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
    bool fetchCurrentUserActions = true,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/library/$libraryId/games',
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          'fetchCurrentUserActions': fetchCurrentUserActions.toString(),
        },
      );
      
      return PagedGameWithUserResponse.fromJson(response.data);
    } catch (e) {
      print('Error getting games by library ID: $e');
      return PagedGameWithUserResponse(content: []);
    }
  }

  // Update custom library details
  Future<UserGameLibrary?> updateCustomLibrary(int libraryId, String title, bool isPrivate) async {
    try {
      final response = await _apiService.put(
        '/api/library/update-custom', 
        {
          'id': libraryId,
          'title': title,
          'isPrivate': isPrivate, 
        },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
         try {
            // Use the correct class name UserGameLibrary
            return UserGameLibrary.fromJson(response.data as Map<String, dynamic>);
         } catch (parseError) {
            print('Error parsing UserGameLibrary response in updateCustomLibrary: $parseError');
            return null; 
         }
      } else {
         print('Error updating custom library: Status code ${response.statusCode}');
         return null;
      }
    } on DioException catch (e) {
      print('Error updating custom library: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Unexpected error updating custom library: $e');
      return null;
    }
  }

  // Create a new custom library
  Future<UserGameLibrary?> createCustomLibrary(String title) async {
    try {
      // Append title as a query parameter directly to the path
      final path = '/api/library?title=${Uri.encodeComponent(title)}';
      
      final response = await _apiService.post(
        path, 
        {}, // Pass an empty map instead of null
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response body into UserGameLibrary
        return UserGameLibrary.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('Error creating custom library: Status code ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('Error creating custom library: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Unexpected error creating custom library: $e');
      return null;
    }
  }

  // Delete a custom library
  Future<bool> deleteCustomLibrary(int libraryId) async {
    try {
      final response = await _apiService.delete(
        '/api/library/custom/$libraryId', // Endpoint path with libraryId
      );
      // Assuming 200 OK or 204 No Content for success
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('Error deleting custom library: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('Unexpected error deleting custom library: $e');
      return false;
    }
  }

  // Add game to a custom library
  // Returns the added game details on success, null otherwise
  Future<GameDetailWithUserInfo?> addGameToLibrary(int libraryId, int gameId) async {
    try {
      final path = '/api/library/$libraryId/games?gameId=$gameId';
      final response = await _apiService.post(path, {});
      // Check for success and if data is a Map
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        try {
          // Parse the response Map into GameDetailWithUserInfo
          return GameDetailWithUserInfo.fromJson(response.data as Map<String, dynamic>);
        } catch (parseError) {
           print('Error parsing GameDetailWithUserInfo response in addGameToLibrary: $parseError');
           return null; // Return null if parsing fails
        }
      } else {
        print('Error adding game or unexpected response: Status ${response.statusCode}, Data Type: ${response.data?.runtimeType}');
        return null; 
      }
    } catch (e) {
      print('Error adding game to library $libraryId: $e');
      return null;
    }
  }

  // Remove game from a custom library
  Future<bool> removeGameFromLibrary(int libraryId, int gameId) async {
    try {
      // DELETE /api/library/{libraryId}/games?gameId={gameId}
      final path = '/api/library/$libraryId/games?gameId=$gameId';
      final response = await _apiService.delete(path);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error removing game from library $libraryId: $e');
      return false;
    }
  }

  // Get status of a game in user's custom libraries
  Future<List<LibrarySummaryWithGameStatusResponse>> getGamePresenceInCustomLibraries(int gameId) async {
    try {
      // Get the current user ID
      final currentUserId = await _tokenService.getUserId();
      if (currentUserId == null) {
        throw Exception("Current user ID not found for checking library status.");
      }

      // Path remains the same, add userId as query parameter
      final String path = '/api/library/custom-lists-status';
      final response = await _apiService.get(
        path,
        queryParameters: {
          'userId': currentUserId.toString(),
          'gameId': gameId.toString(),
        }
      );
      if (response.data is List) {
        return (response.data as List)
            .map((json) => LibrarySummaryWithGameStatusResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Unexpected response format for custom library status: ${response.data?.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error getting game presence in custom libraries: $e');
      return []; // Return empty list on error
    }
  }

  // Ensure fetchUserLibraries uses the base LibrarySummaryResponse
  Future<List<LibrarySummaryResponse>> fetchUserLibraries() async {
    const String path = '/api/library/my-libraries';
    try {
      final response = await _apiService.get(path);
      if (response.data is List) {
        // Use the base class factory here
        return (response.data as List)
            .map((json) => LibrarySummaryResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Unexpected response format for user libraries: ${response.data?.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error fetching user libraries: $e');
      return [];
    }
  }

  // --- Currently Playing Methods --- 

  /// Adds a game to the user's currently playing list.
  /// 
  /// Returns the GameDetailWithUserInfo of the added game if successful, null otherwise.
  Future<GameDetailWithUserInfo?> addToCurrentlyPlaying(int gameId) async {
    final String path = '/api/library/currently-playing/add?gameId=$gameId';
    try {
      final response = await _apiService.post(path, {}); // POST with empty body
      
      // Check for success status and parse the response body
      if (response.statusCode == 200 && response.data != null) {
         try {
            // Assuming response.data is Map<String, dynamic>
            return GameDetailWithUserInfo.fromJson(response.data as Map<String, dynamic>);
         } catch (parseError) {
            print('Error parsing GameDetailWithUserInfo response: $parseError');
            return null; // Return null if parsing fails
         }
      } else {
         print('Failed to add game $gameId to currently playing. Status: ${response.statusCode}');
         return null;
      }
    } catch (e) {
      print('Error adding game $gameId to currently playing: $e');
      return null;
    }
  }

  /// Removes a game from the user's currently playing list.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> removeFromCurrentlyPlaying(int gameId) async {
    final String path = '/api/library/currently-playing/remove?gameId=$gameId';
    try {
      // Controller uses POST, but logically might be DELETE? 
      // Sticking to POST as per controller definition.
      final response = await _apiService.post(path, {}); // POST with empty body
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing game $gameId from currently playing: $e');
      return false;
    }
  }

  /// Fetches the list of games currently being played by the user.
  /// 
  /// Returns a list of game details with user info, or an empty list on error.
  Future<List<GameDetailWithUserInfo>> getCurrentlyPlayingGames() async {
    const String path = '/api/library/currently-playing/games';
    try {
      final response = await _apiService.get(path);
      if (response.data is List) {
        return (response.data as List)
            .map((json) => GameDetailWithUserInfo.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Unexpected response format for currently playing games: ${response.data?.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error fetching currently playing games: $e');
      return [];
    }
  }

  // --- Follow/Unfollow Methods --- 

  Future<bool> followLibrary(int libraryId) async {
    try {
      final response = await _apiService.post('/api/library/$libraryId/follow', {});
      return response.statusCode == 200;
    } catch (e) {
      print('Error following library $libraryId: $e');
      return false;
    }
  }

  Future<bool> unfollowLibrary(int libraryId) async {
    try {
      final response = await _apiService.delete('/api/library/$libraryId/follow');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unfollowing library $libraryId: $e');
      return false;
    }
  }

  // --- Get Followers Method --- 

  Future<PagedResponse<UserFollowerResponse>?> getLibraryFollowers(int libraryId, {int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.get(
         '/api/library/$libraryId/followers',
         queryParameters: {
            'page': page.toString(),
            'size': size.toString(),
         },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
         try {
            return PagedResponse<UserFollowerResponse>.fromJson(
               response.data as Map<String, dynamic>,
               (json) => UserFollowerResponse.fromJson(json as Map<String, dynamic>),
            );
         } catch (parseError) {
            print('Error parsing followers page response: $parseError');
            return null;
         }
      } else {
         print('Error fetching followers: Status code ${response.statusCode}');
         return null;
      }
    } catch (e) {
      print('Error fetching library followers for $libraryId: $e');
      return null;
    }
  }

  // --- Get Followed Libraries by User ---
  Future<PagedResponse<LibrarySummaryResponse>?> getFollowedLibrariesByUser(
    int userId, 
    {int page = 0, int size = 20}
  ) async {
    try {
      final response = await _apiService.get(
         '/api/library/users/$userId/followed-libraries',
         queryParameters: {
            'page': page.toString(),
            'size': size.toString(),
         },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
         try {
            return PagedResponse<LibrarySummaryResponse>.fromJson(
               response.data as Map<String, dynamic>,
               (json) => LibrarySummaryResponse.fromJson(json as Map<String, dynamic>),
            );
         } catch (parseError) {
            print('Error parsing followed libraries page response: $parseError');
            return null;
         }
      } else {
         print('Error fetching followed libraries: Status code ${response.statusCode}');
         return null;
      }
    } catch (e) {
      print('Error fetching followed libraries for user $userId: $e');
      return null;
    }
  }
} 