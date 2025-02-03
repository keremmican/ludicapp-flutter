import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;

  final _storage = const FlutterSecureStorage();
  static const _tokenExpiryThreshold = Duration(minutes: 5);

  TokenService._internal();

  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String username,
  }) async {
    developer.log('Saving auth data to secure storage', name: 'TokenService');
    developer.log('Auth data - userId: $userId, username: $username', name: 'TokenService');
    
    await _storage.write(key: 'token', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    await _storage.write(key: 'userId', value: userId.toString());
    await _storage.write(key: 'username', value: username);
    
    developer.log('Auth data saved successfully', name: 'TokenService');
  }

  Future<void> clearAuthData() async {
    developer.log('Clearing all auth data from secure storage', name: 'TokenService');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'username');
    developer.log('Auth data cleared successfully', name: 'TokenService');
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: 'token');
    developer.log('Retrieved access token: ${token != null ? 'exists' : 'null'}', name: 'TokenService');
    return token;
  }

  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: 'refreshToken');
    developer.log('Retrieved refresh token: ${token != null ? 'exists' : 'null'}', name: 'TokenService');
    return token;
  }

  Future<int?> getUserId() async {
    final idStr = await _storage.read(key: 'userId');
    developer.log('Retrieved userId: $idStr', name: 'TokenService');
    return idStr != null ? int.parse(idStr) : null;
  }

  Future<String?> getUsername() async {
    final username = await _storage.read(key: 'username');
    developer.log('Retrieved username: $username', name: 'TokenService');
    return username;
  }

  Future<bool> shouldRefreshToken() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final now = DateTime.now();

      return expiryDate.difference(now) < _tokenExpiryThreshold;
    } catch (e) {
      print('Token Check Error: $e');
      return true;
    }
  }
} 