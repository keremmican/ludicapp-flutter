import 'dart:convert';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/search_game.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';

class SearchRepository {
  final ApiService _apiService = ApiService();

  Future<PageableResponse<SearchGame>> searchGames(
    String query,
    int page,
    int size,
  ) async {
    print('Making request to: /search?query=$query&page=$page&size=$size');
    
    final response = await _apiService.get(
      '/search',
      queryParameters: {
        'query': query,
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    print('Raw Response: ${response.data}');

    // API yanıtını Map'e dönüştür
    final Map<String, dynamic> jsonData = response.data is String 
        ? json.decode(response.data as String)
        : response.data as Map<String, dynamic>;

    return PageableResponse.fromJson(
      jsonData,
      (json) => SearchGame.fromJson(json as Map<String, dynamic>),
    );
  }
}
