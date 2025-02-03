class UserLightResponse {
  final int id;
  final String username;

  UserLightResponse({
    required this.id,
    required this.username,
  });

  factory UserLightResponse.fromJson(Map<String, dynamic> json) {
    return UserLightResponse(
      id: json['id'] as int,
      username: json['username'] as String,
    );
  }
}

class AuthResponse {
  final UserLightResponse user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserLightResponse.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
} 