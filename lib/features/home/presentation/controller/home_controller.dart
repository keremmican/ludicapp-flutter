import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/repository/game_repository.dart';

class HomeController {
  static final HomeController _instance = HomeController._internal();
  factory HomeController() => _instance;
  HomeController._internal();

  final GameRepository _gameRepository = GameRepository();

  List<GameSummary> newReleases = [];
  List<GameSummary> topRatedGames = [];
  GameSummary? randomGame;
  String? error;

  bool _isInitialized = false;

  Future<void> initializeData() async {
    if (_isInitialized) return;

    try {
      final newReleasesResponse = await _gameRepository.fetchNewReleases();
      final topRatedResponse = await _gameRepository.fetchTopRatedGames();

      newReleases = newReleasesResponse.content;
      topRatedGames = topRatedResponse.content;
      randomGame = newReleasesResponse.content.isNotEmpty ? newReleasesResponse.content.first : null;
      
      _isInitialized = true;
    } catch (e) {
      error = e.toString();
    }
  }
} 