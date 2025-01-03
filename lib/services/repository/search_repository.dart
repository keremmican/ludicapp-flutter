import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/search_game.dart';

class SearchRepository {
  final ApiService _apiService = ApiService();

  Future<SearchResponse> searchGames(String query, int page, int size) async {
    final url = '/search?query=$query&page=$page&size=$size';
    print('Making request to: $url');
    
    final response = await _apiService.get(url);
    print('Raw Response: ${response.data}');
    
    final searchResponse = SearchResponse.fromJson(response.data);
    print('Parsed Response - Content Size: ${searchResponse.content.length}');
    return searchResponse;
  }
}
