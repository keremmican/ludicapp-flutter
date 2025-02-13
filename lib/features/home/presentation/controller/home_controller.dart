import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';

class HomeController {
  static final HomeController _instance = HomeController._internal();
  factory HomeController() => _instance;
  HomeController._internal();

  final GameRepository _gameRepository = GameRepository();

  List<GameSummary> newReleases = [];
  List<GameSummary> topRatedGames = [];
  List<GameSummary> comingSoonGames = [];
  GameSummary? randomGame;
  GameSummary? popularGameByVisits;
  Map<int, List<GameSummary>> popularityTypeGames = {};
  bool isLoadingMoreSections = false;
  String? error;

  bool _isInitialized = false;
  int _currentBatchIndex = 0;

  // Tüm popularity type ID'leri (1 hariç çünkü o showcase için kullanılıyor)
  static const List<List<int>> _popularityTypeBatches = [
    [1, 4, 3, 10],    // İlk batch: Want to Play, Played, Playing, Total Reviews
    [5, 6, 2, 9],
  ];

  static const Map<int, String> popularityTypeTitles = {
    1: 'Trending Now',
    2: 'Most Wanted',
    3: 'Most Played (now)',
    4: 'Most Played',
    5: '24hr Peak Players',
    6: 'Most Positive Reviews',
    8: 'Most Reviews',
    9: 'Global Top Sellers',
    10: 'Most Wishlisted',
  };

  void setInitialData({
    required List<GameSummary> newReleases,
    required List<GameSummary> topRatedGames,
    required List<GameSummary> comingSoonGames,
    GameSummary? popularGameByVisits,
  }) {
    this.newReleases = newReleases;
    this.topRatedGames = topRatedGames;
    this.comingSoonGames = comingSoonGames;
    this.randomGame = newReleases.isNotEmpty ? newReleases.first : null;
    this.popularGameByVisits = popularGameByVisits;
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

      if (SplashScreen.visitsPopularityTypeId != null) {
        popularGameByVisits = await _gameRepository.getSingleGameByPopularityType(
          SplashScreen.visitsPopularityTypeId!
        );
      }
      
      _isInitialized = true;
    } catch (e) {
      error = e.toString();
    }
  }

  Future<void> loadMoreSections() async {
    if (isLoadingMoreSections || _currentBatchIndex >= _popularityTypeBatches.length) return;

    try {
      isLoadingMoreSections = true;

      // Get current batch of popularity types
      final currentBatch = _popularityTypeBatches[_currentBatchIndex];
      
      // Load games for each popularity type in this batch
      for (final popularityType in currentBatch) {
        if (!popularityTypeGames.containsKey(popularityType)) {
          final response = await _gameRepository.fetchGamesByPopularityType(
            popularityType: popularityType,
          );
          popularityTypeGames[popularityType] = response.content;
        }
      }

      // Move to next batch
      _currentBatchIndex++;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingMoreSections = false;
    }
  }

  bool get hasMoreSections => _currentBatchIndex < _popularityTypeBatches.length;

  String getPopularityTypeTitle(int popularityType) {
    return popularityTypeTitles[popularityType] ?? 'Popular Games';
  }
} 