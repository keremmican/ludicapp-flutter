import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/models/profile_response.dart';
import 'package:ludicapp/services/token_service.dart';

class UserRepository {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  Future<ProfileResponse> fetchUserProfile() async {
    final userId = await _tokenService.getUserId();
    if (userId == null) {
      throw Exception('User ID not found');
    }

    print('Fetching profile for userId: $userId');
    final response = await _apiService.get(
      "/v1/users/profile",
      queryParameters: {
        'userId': userId.toString(),
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
  }
}
