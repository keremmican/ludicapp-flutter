import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://10.0.2.2:8081/", // Backend'inizin base URL'si
    connectTimeout: const Duration(seconds: 5), // 5 saniye
    receiveTimeout: const Duration(seconds: 3), // 3 saniye
  ));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // İleride JWT token kullanımı için örnek:
        // options.headers['Authorization'] = 'Bearer your_jwt_token';
        return handler.next(options); // İşleme devam et
      },
      onError: (error, handler) {
        print("API Error: ${error.message}");
        return handler.next(error); // Hata ile devam et
      },
    ));
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      // Hata yönetimi...
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
