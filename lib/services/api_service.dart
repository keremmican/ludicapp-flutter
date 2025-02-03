import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ludicapp/core/config/environment_config.dart';
import 'package:ludicapp/services/token_service.dart';
import 'dart:convert';
import 'dart:async';

class ApiService {
  static final navigatorKey = GlobalKey<NavigatorState>();
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvironmentConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final _tokenService = TokenService();
  bool _isRefreshing = false;

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // /api/auth ile başlayan endpointler hariç hepsinde token gerekli
        if (!options.path.startsWith('/api/auth')) {
          final token = await _tokenService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            // Refresh token'ı al
            final refreshToken = await _tokenService.getRefreshToken();
            if (refreshToken == null) {
              throw DioException(
                requestOptions: error.requestOptions,
                error: 'No refresh token available',
              );
            }

            // Yeni access token al
            final response = await _dio.post(
              '/api/auth/refresh-token',
              queryParameters: {'refreshToken': refreshToken}, // Query parameter olarak gönder
              data: {}, // Boş body
            );

            if (response.statusCode == 200) {
              final newAccessToken = response.data['accessToken'] as String;
              
              // Yeni token'ı kaydet
              final userId = await _tokenService.getUserId();
              final username = await _tokenService.getUsername();
              
              if (userId != null && username != null) {
                await _tokenService.saveAuthData(
                  accessToken: newAccessToken,
                  refreshToken: refreshToken,
                  userId: userId,
                  username: username,
                );

                // Orijinal isteği yeni token ile tekrarla
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );
                
                final cloneReq = await _dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                
                return handler.resolve(cloneReq);
              }
            }
            throw error;
          } catch (e) {
            // Refresh token da geçersizse veya başka bir hata olduysa
            await _tokenService.clearAuthData();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/landing',
              (route) => false,
            );
            return handler.next(error);
          } finally {
            _isRefreshing = false;
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    return await _dio.post(endpoint, data: data);
  }

  Future<Response> put(String endpoint, Map<String, dynamic> data) async {
    return await _dio.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) async {
    return await _dio.delete(endpoint);
  }
}
