import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/models/profile_response.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'package:ludicapp/services/model/response/paged_response.dart';
import 'package:ludicapp/services/model/response/user_follower_response.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';

class UserRepository {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  // Stream controller to notify listeners about profile updates
  static final List<Function()> _profileUpdateListeners = [];

  // Add listener for profile updates
  static void addProfileUpdateListener(Function() listener) {
    _profileUpdateListeners.add(listener);
  }

  // Remove listener
  static void removeProfileUpdateListener(Function() listener) {
    _profileUpdateListeners.remove(listener);
  }

  // Notify all listeners about profile update
  static void notifyProfileUpdate() {
    for (var listener in _profileUpdateListeners) {
      listener();
    }
  }

  // Refresh current user's profile data
  Future<void> refreshCurrentUserProfile() async {
    try {
      final response = await fetchUserProfile();
      // Update the cached profile data
      SplashScreen.profileData = response;
      // Notify listeners about the update
      notifyProfileUpdate();
    } catch (e) {
      print('Error refreshing profile: $e');
    }
  }

  Future<ProfileResponse> fetchUserProfile({String? userId}) async {
    final currentUserId = await _tokenService.getUserId();
    final targetUserId = userId ?? currentUserId.toString();
    
    if (targetUserId == null) {
      throw Exception('User ID not found');
    }

    print('Fetching profile for userId: $targetUserId');
    final response = await _apiService.get(
      "/v1/users/profile",
      queryParameters: {
        'userId': targetUserId,
      },
    );

    print('Profile API Response: ${response.data}');
    final profileResponse = ProfileResponse.fromJson(response.data);
    print('Parsed Profile Response: $profileResponse');
    return profileResponse;
  }

  Future<Map<String, dynamic>> fetchUserDetails() async {
    final response = await _apiService.get("/user/details");
    return response.data;
  }

  Future<void> updateUserDetails(Map<String, dynamic> data) async {
    await _apiService.post("/user/update", data);
    // After updating user details, refresh the profile
    await refreshCurrentUserProfile();
  }

  // --- Follow/Unfollow Methods ---

  Future<bool> followUser(int userId) async {
    try {
      // Assume POST /v1/users/{userId}/follow
      final response = await _apiService.post('/v1/users/$userId/follow', {});
      return response.statusCode == 200;
    } catch (e) {
      print('Error following user $userId: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(int userId) async {
    try {
      // Assume DELETE /v1/users/{userId}/follow
      final response = await _apiService.delete('/v1/users/$userId/follow');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unfollowing user $userId: $e');
      return false;
    }
  }

  // --- Get Followers/Following ---

  Future<PagedResponse<UserFollowerResponse>> getFollowers(int userId, {int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.get(
        '/v1/users/$userId/followers',
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
        },
      );
      // Assuming PagedResponse.fromJson correctly handles the nested UserFollowerResponse list
      return PagedResponse<UserFollowerResponse>.fromJson(
        response.data,
        (json) => UserFollowerResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('Error fetching followers for user $userId: $e');
      rethrow; // Rethrow to allow calling code to handle
    }
  }

  Future<PagedResponse<UserFollowerResponse>> getFollowing(int userId, {int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.get(
        '/v1/users/$userId/following',
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
        },
      );
      // Assuming PagedResponse.fromJson correctly handles the nested UserFollowerResponse list
      return PagedResponse<UserFollowerResponse>.fromJson(
        response.data,
        (json) => UserFollowerResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('Error fetching following for user $userId: $e');
      rethrow; // Rethrow to allow calling code to handle
    }
  }

  // Update user profile including username and profile photo
  Future<ProfileResponse> updateUserProfile({
    required String username,
    required ProfilePhotoType profilePhotoType,
    String? profilePhotoUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'username': username,
        'profilePhotoType': profilePhotoType.name,
      };
      
      // Only include profilePhotoUrl if it's not null and type is CUSTOM
      if (profilePhotoType == ProfilePhotoType.CUSTOM && profilePhotoUrl != null) {
        data['profilePhotoUrl'] = profilePhotoUrl;
      }
      
      print('Updating profile with data: $data');
      final response = await _apiService.put('/v1/users/update-profile', data);
      print('Profile update response: $response, status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        // Başarılı bir cevap alındı
        print('Profile update successful');
        ProfileResponse profileResponse;
        
        // Eğer cevap boş veya geçersizse, yeni profil verilerini tekrar çekelim
        if (response.data == null || response.data is! Map<String, dynamic>) {
          print('Response data is null or invalid, fetching fresh profile data');
          profileResponse = await fetchUserProfile();
        } else {
          print('Parsing response data: ${response.data}');
          profileResponse = ProfileResponse.fromJson(response.data);
        }
        
        // Update the cached profile data
        SplashScreen.profileData = profileResponse;
        
        // Notify listeners about the update
        notifyProfileUpdate();
        
        return profileResponse;
      } else {
        throw Exception('Failed to update profile: Status ${response.statusCode}, ${response.statusMessage}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow; // Rethrow to allow calling code to handle the error
    }
  }
}
