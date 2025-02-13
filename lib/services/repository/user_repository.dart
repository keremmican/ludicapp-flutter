import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/models/profile_response.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';

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
}
