import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/game_detail.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/top_games_cover.dart';

class GameRepository {
  final ApiService _apiService = ApiService();

  Future<List<GameSummary>> fetchNewReleases() async {
    final response = await _apiService.get("/games/new-releases");

    // Gelen veri bir liste olduğu için, her bir JSON elemanını GameSummary'e dönüştürüyoruz
    return (response.data as List)
        .map((game) => GameSummary.fromJson(game))
        .toList();
  }

  Future<List<TopRatedGamesCover>> fetchTopRatedGames() async {
    final response = await _apiService.get("/games/top-games");

    // Gelen veri bir liste olduğu için, her bir JSON elemanını GameSummary'e dönüştürüyoruz
    return (response.data as List)
        .map((game) => TopRatedGamesCover.fromJson(game))
        .toList();
  }

  Future<GameDetail> fetchGameDetails(int gameId) async {
    final response = await _apiService.get("/games/detail/$gameId");

    // Gelen veriyi `GameDetail` modeline dönüştür
    return GameDetail.fromJson(response.data);
  }
}
