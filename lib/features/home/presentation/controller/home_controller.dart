import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/repository/game_repository.dart';

class HomeController {
  static final HomeController _instance = HomeController._internal();
  factory HomeController() => _instance;
  HomeController._internal();

  final GameRepository _gameRepository = GameRepository();

  List<GameSummary> newReleases = [];
  List<GameSummary> topRatedGames = [];
  List<GameSummary> comingSoonGames = [];
  GameSummary? randomGame;
  String? error;

  bool _isInitialized = false;

  void setInitialData({
    required List<GameSummary> newReleases,
    required List<GameSummary> topRatedGames,
    required List<GameSummary> comingSoonGames,
  }) {
    this.newReleases = newReleases;
    this.topRatedGames = topRatedGames;
    this.comingSoonGames = comingSoonGames;
    this.randomGame = newReleases.isNotEmpty ? newReleases.first : null;
    _isInitialized = true;
  }

  Future<void> initializeData() async {
    if (_isInitialized) return;

    try {
      final newReleasesResponse = await _gameRepository.fetchNewReleases();
      final topRatedResponse = await _gameRepository.fetchTopRatedGames();
      final comingSoonResponse = await _gameRepository.fetchComingSoon();

      newReleases = newReleasesResponse.content;
      topRatedGames = topRatedResponse.content;
      comingSoonGames = comingSoonResponse.content;
      randomGame = newReleasesResponse.content.isNotEmpty ? newReleasesResponse.content.first : null;
      
      _isInitialized = true;
    } catch (e) {
      error = e.toString();
    }
  }
} 