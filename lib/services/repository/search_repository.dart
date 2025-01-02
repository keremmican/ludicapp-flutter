import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/search_game.dart';

class SearchRepository {
  final ApiService _apiService = ApiService();

  Future<SearchResponse> searchGames(String query, int page, int size) async {
    final url = '/search?query=$query&page=$page&size=$size';
    print('Making request to: $url');
    
    final response = await _apiService.get(url);
    
    final searchResponse = SearchResponse.fromJson(response.data);
    print('Received ${searchResponse.content.length} results for page $page');
    return searchResponse;
  }
}
