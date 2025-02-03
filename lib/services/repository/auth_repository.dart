import 'dart:convert';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/models/auth_response.dart';
import 'package:ludicapp/models/user_light_response.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:developer' as developer;
import 'dart:core';
import 'package:dio/dio.dart';

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;

  final _apiService = ApiService();
  final _tokenService = TokenService();
  static const _tokenExpiryThreshold = Duration(minutes: 5);

  AuthRepository._internal();

  Future<AuthResponse> register(String emailOrPhone, String username) async {
    developer.log('Starting registration process', name: 'AuthRepository');
    developer.log('Registration params: emailOrPhone=$emailOrPhone, username=$username', name: 'AuthRepository');

    final response = await _apiService.post('/api/auth/register', {
      'emailOrPhone': emailOrPhone,
      'username': username,
    });

    developer.log('Registration response received: ${response.data}', name: 'AuthRepository');

    final Map<String, dynamic> data = response.data;
    final Map<String, dynamic> user = data['user'];
    final String accessToken = data['accessToken'];
    final String refreshToken = data['refreshToken'];

    developer.log('Parsed auth data - userId: ${user['id']}, username: ${user['username']}', name: 'AuthRepository');

    final authResponse = AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: UserLightResponse(
        id: user['id'],
        username: user['username'],
      ),
    );

    developer.log('Saving auth data to storage...', name: 'AuthRepository');
    await _tokenService.saveAuthData(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      userId: authResponse.user.id,
      username: authResponse.user.username,
    );
    developer.log('Auth data saved successfully', name: 'AuthRepository');

    return authResponse;
  }

  Future<bool> signOut() async {
    try {
      developer.log('Starting sign out process', name: 'AuthRepository');
      final userId = await _tokenService.getUserId();
      
      if (userId == null) {
        developer.log('SignOut Error: userId is null', name: 'AuthRepository');
        return false;
      }

      developer.log('SignOut Request - userId: $userId', name: 'AuthRepository');

      await _apiService.post('/api/auth/signout', {
        'userId': userId,
      });

      developer.log('SignOut request successful, clearing auth data', name: 'AuthRepository');
      await _tokenService.clearAuthData();
      return true;
    } catch (e) {
      developer.log('SignOut Error: $e', error: e, name: 'AuthRepository');
      await _tokenService.clearAuthData();
      return true;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      developer.log('Checking authentication status', name: 'AuthRepository');
      final token = await _tokenService.getAccessToken();
      
      if (token == null) {
        developer.log('No access token found', name: 'AuthRepository');
        return false;
      }

      developer.log('Access token found, validating...', name: 'AuthRepository');
      final response = await _apiService.get('/api/auth/validate-token');
      developer.log('Token validation response: ${response.statusCode}', name: 'AuthRepository');
      
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Auth check error: $e', error: e, name: 'AuthRepository');
      if (e is DioException && e.response?.statusCode == 401) {
        developer.log('Got 401, clearing auth data', name: 'AuthRepository');
        await _tokenService.clearAuthData();
      }
      return false;
    }
  }

  Future<UserLightResponse?> getCurrentUser() async {
    try {
      developer.log('Getting current user info', name: 'AuthRepository');
      
      if (!await isAuthenticated()) {
        developer.log('User is not authenticated', name: 'AuthRepository');
        return null;
      }

      final userId = await _tokenService.getUserId();
      final username = await _tokenService.getUsername();

      developer.log('Retrieved user data - userId: $userId, username: $username', name: 'AuthRepository');

      if (userId == null || username == null) {
        developer.log('Missing user data (userId or username is null)', name: 'AuthRepository');
        return null;
      }

      return UserLightResponse(
        id: userId,
        username: username,
      );
    } catch (e) {
      developer.log('Get current user error: $e', error: e, name: 'AuthRepository');
      return null;
    }
  }

  Future<Map<String, dynamic>> checkUserExists({
    required String emailOrPhone,
    required bool isLoginFlow,
  }) async {
    try {
      print('Auth Request - checkUserExists: {emailOrPhone: $emailOrPhone, isLoginFlow: $isLoginFlow}');

      final response = await _apiService.get(
        '/api/auth/check-user-exists',
        queryParameters: {
          'emailOrPhone': emailOrPhone,
          'isLoginFlow': isLoginFlow,
        },
      );

      print('Auth Response: ${response.data}');
      return {'success': true, 'message': ''};
    } catch (e) {
      print('Auth Response (Error): $e');
      
      if (e.toString().contains('400')) {
        return {
          'success': false,
          'message': isLoginFlow ? 'User not found' : 'Email is already in use'
        };
      }
      
      return {'success': false, 'message': 'An error occurred, please try again'};
    }
  }

  Future<bool> sendOtp({required String emailOrPhone}) async {
    try {
      await _apiService.post(
        '/api/auth/send-otp?emailOrPhone=$emailOrPhone',
        {},
      );
      print('Send OTP Success for: $emailOrPhone');
      return true;
    } catch (e) {
      print('Send OTP Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String emailOrPhone,
    required String code,
    required bool isLoginFlow,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/auth/verify-otp?emailOrPhone=$emailOrPhone&code=$code&isLoginFlow=$isLoginFlow',
        {},
      );

      if (response.statusCode == 200) {
        if (isLoginFlow) {
          // Login flow için response bir map olmalı
          if (response.data is! Map<String, dynamic>) {
            developer.log('Unexpected response type for login flow: ${response.data}');
            return {
              'success': false,
              'message': 'Unexpected response format',
            };
          }

          final Map<String, dynamic> data = response.data;
          final String accessToken = data['accessToken'];
          final String refreshToken = data['refreshToken'];
          final Map<String, dynamic> user = data['user'];

          await _tokenService.saveAuthData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: user['id'],
            username: user['username'],
          );

          return {
            'success': true,
            'message': 'Login successful',
          };
        } else {
          // Register flow için response'un içeriği önemli değil, sadece status code'a bakıyoruz
          return {
            'success': true,
            'message': 'Verification successful',
          };
        }
      }

      return {
        'success': false,
        'message': 'Invalid verification code',
      };
    } catch (e) {
      developer.log('Verify OTP Error: $e');
      return {
        'success': false,
        'message': 'An error occurred during verification',
      };
    }
  }

  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiService.post(
        '/api/auth/refresh-token?refreshToken=$refreshToken',
        {},
      );

      final newAccessToken = response.data['accessToken'] as String;
      final userId = await _tokenService.getUserId();
      final username = await _tokenService.getUsername();
      
      if (userId == null || username == null) {
        return false;
      }

      await _tokenService.saveAuthData(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
        userId: userId,
        username: username,
      );
      return true;
    } catch (e) {
      print('Refresh Token Error: $e');
      await _tokenService.clearAuthData();
      return false;
    }
  }

  Future<bool> checkAndRefreshToken() async {
    final accessToken = await _tokenService.getAccessToken();
    if (accessToken == null) return false;

    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final now = DateTime.now();

      if (expiryDate.difference(now) < _tokenExpiryThreshold) {
        return await refreshAccessToken();
      }
      return true;
    } catch (e) {
      print('Token Check Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> checkUsernameExists(String username) async {
    try {
      print('Auth Request - checkUsernameExists: {username: $username}');

      final response = await _apiService.get(
        '/api/auth/check-username-exists',
        queryParameters: {
          'username': username,
        },
      );

      print('Auth Response: ${response.data}');
      return {'success': true, 'message': ''};
    } catch (e) {
      print('Auth Response (Error): $e');
      
      if (e is DioException && e.response?.statusCode == 400) {
        return {
          'success': false,
          'message': 'Username already exists'
        };
      }
      
      return {'success': false, 'message': 'An error occurred, please try again'};
    }
  }

  Future<bool> registerFromOnboarding({
    required String emailOrPhone,
    required String username,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/auth/register',
        {
          'emailOrPhone': emailOrPhone,
          'username': username,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String accessToken = data['accessToken'];
        final String refreshToken = data['refreshToken'];
        final Map<String, dynamic> user = data['user'];

        await _tokenService.saveAuthData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: user['id'],
          username: user['username'],
        );

        return true;
      }

      return false;
    } catch (e) {
      developer.log('Register Error: $e');
      return false;
    }
  }
} 