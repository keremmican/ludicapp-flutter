import 'package:ludicapp/services/api_service.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchUserDetails() async {
    final response = await _apiService.get("/user/details");
    return response.data;
  }

  Future<void> updateUserDetails(Map<String, dynamic> data) async {
    await _apiService.post("/user/update", data);
  }
}
