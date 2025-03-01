import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/name_id_response.dart';
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
  Map<GameSummary, List<GameSummary>> popularityTypeGames = {};
  bool isLoadingMoreSections = false;
  String? error;

  bool _isInitialized = false;
  int _currentBatchIndex = 0;

  // Tüm popularity type ID'leri (1 hariç çünkü o showcase için kullanılıyor)
  static const List<List<int>> _popularityTypeBatches = [
    [1],
    [4],    // İlk batch: Most Played (büyük kart)
    [3],    // İkinci batch: Most Played (now) (küçük kart)
    [10],   // Üçüncü batch: Most Wishlisted (büyük kart)
    [5],    // Dördüncü batch: 24hr Peak Players (küçük kart)
    [6],    // Beşinci batch: Most Positive Reviews (büyük kart)
    [8],
    [2],    // Altıncı batch: Most Wanted (küçük kart)
    [9],    // Yedinci batch: Global Top Sellers (büyük kart)
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

  // Popularity type'ları döndüren getter
  List<NameIdResponse> get popularityTypes => 
      SplashScreen.popularityTypes?.where((type) => type.id != SplashScreen.visitsPopularityTypeId).toList() ?? [];

  // Belirli bir popülerlik tipi için oyunları döndüren metot
  List<GameSummary> getGamesForPopularityType(int popularityTypeId) {
    final typeObj = popularityTypes.firstWhere(
      (type) => type.id == popularityTypeId,
      orElse: () => NameIdResponse(id: popularityTypeId, name: getPopularityTypeTitle(popularityTypeId)),
    );
    
    return popularityTypeGames.entries
      .where((entry) => entry.key.id == typeObj.id)
      .map((entry) => entry.value)
      .firstOrNull ?? [];
  }

  // Belirli bir bölüm için veri yükleyen metot
  Future<void> loadSpecificSection(List<int> popularityTypeIds) async {
    try {
      isLoadingMoreSections = true;
      
      // Belirtilen popülerlik tipleri için oyunları yükle
      for (final popularityType in popularityTypeIds) {
        if (!popularityTypeGames.values.any((games) => games.isNotEmpty && games.first.id == popularityType)) {
          final response = await _gameRepository.fetchGamesByPopularityType(
            popularityType: popularityType,
          );
          
          // Popularity type'ı bul
          final typeObj = popularityTypes.firstWhere(
            (type) => type.id == popularityType,
            orElse: () => NameIdResponse(id: popularityType, name: getPopularityTypeTitle(popularityType)),
          );
          
          // NameIdResponse'u GameSummary'ye dönüştür
          final gameSummary = GameSummary(
            id: typeObj.id,
            name: typeObj.name,
            slug: typeObj.name.toLowerCase().replaceAll(' ', '-'),
            genres: [],
            themes: [],
            platforms: [],
            companies: [],
            screenshots: [],
            gameVideos: [],
            franchises: [],
            gameModes: [],
            playerPerspectives: [],
            languageSupports: [],
          );
          
          popularityTypeGames[gameSummary] = response.content;
        }
      }
    } catch (e) {
      error = e.toString();
      throw e; // Hatayı yukarı ilet
    } finally {
      isLoadingMoreSections = false;
    }
  }

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

  Future<void> loadData() async {
    if (_isInitialized) return;

    try {
      // Splash screen'de yüklenen verileri kullan
      if (newReleases.isEmpty) {
        final newReleasesResponse = await _gameRepository.fetchNewReleases();
        newReleases = newReleasesResponse.content;
      }
      
      if (topRatedGames.isEmpty) {
        final topRatedResponse = await _gameRepository.fetchTopRatedGames();
        topRatedGames = topRatedResponse.content;
      }
      
      if (comingSoonGames.isEmpty) {
        final comingSoonResponse = await _gameRepository.fetchComingSoon();
        comingSoonGames = comingSoonResponse.content;
      }
      
      if (randomGame == null && newReleases.isNotEmpty) {
        randomGame = newReleases.first;
      }

      if (popularGameByVisits == null && SplashScreen.visitsPopularityTypeId != null) {
        popularGameByVisits = await _gameRepository.getSingleGameByPopularityType(
          SplashScreen.visitsPopularityTypeId!
        );
      }
      
      _isInitialized = true;
    } catch (e) {
      error = e.toString();
      throw e; // Hatayı yukarı ilet
    }
  }

  Future<void> initializeData() async {
    return loadData();
  }

  Future<void> loadMoreSections() async {
    if (isLoadingMoreSections || _currentBatchIndex >= _popularityTypeBatches.length) return;

    try {
      isLoadingMoreSections = true;

      // Get current batch of popularity types
      final currentBatch = _popularityTypeBatches[_currentBatchIndex];
      
      // Load games for each popularity type in this batch
      for (final popularityType in currentBatch) {
        if (!popularityTypeGames.values.any((games) => games.isNotEmpty && games.first.id == popularityType)) {
          final response = await _gameRepository.fetchGamesByPopularityType(
            popularityType: popularityType,
          );
          
          // Popularity type'ı bul
          final typeObj = popularityTypes.firstWhere(
            (type) => type.id == popularityType,
            orElse: () => NameIdResponse(id: popularityType, name: getPopularityTypeTitle(popularityType)),
          );
          
          // NameIdResponse'u GameSummary'ye dönüştür
          final gameSummary = GameSummary(
            id: typeObj.id,
            name: typeObj.name,
            slug: typeObj.name.toLowerCase().replaceAll(' ', '-'),
            genres: [],
            themes: [],
            platforms: [],
            companies: [],
            screenshots: [],
            gameVideos: [],
            franchises: [],
            gameModes: [],
            playerPerspectives: [],
            languageSupports: [],
          );
          
          popularityTypeGames[gameSummary] = response.content;
        }
      }

      // Move to next batch
      _currentBatchIndex++;
    } catch (e) {
      error = e.toString();
      throw e; // Hatayı yukarı ilet
    } finally {
      isLoadingMoreSections = false;
    }
  }

  bool get hasMoreSections => _currentBatchIndex < _popularityTypeBatches.length;

  String getPopularityTypeTitle(int popularityType) {
    return popularityTypeTitles[popularityType] ?? 'Popular Games';
  }
} 