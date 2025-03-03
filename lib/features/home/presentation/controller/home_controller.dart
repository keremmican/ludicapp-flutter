import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/name_id_response.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/services/model/response/user_game_info.dart';
import 'package:ludicapp/services/model/response/user_game_actions.dart';

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
  Map<int, List<GameDetailWithUserInfo>> popularityTypeGames = {};
  bool isLoadingMoreSections = false;
  String? error;

  // User-specific information
  Map<int, int> userRatings = {}; // gameId -> rating
  Set<int> savedGames = {}; // gameIds that are saved
  Set<int> ratedGames = {}; // gameIds that are rated
  Set<int> hiddenGames = {}; // gameIds that are hidden

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
  List<GameSummary> getGamesForPopularityType(int popularityType) {
    if (!popularityTypeGames.containsKey(popularityType)) return [];
    return popularityTypeGames[popularityType]!.map((gameWithUser) => gameWithUser.gameDetails).toList();
  }

  // GameSummary'den Game nesnesi oluşturan ve userActions bilgisini ekleyen metod
  Game getGameWithUserActions(GameSummary gameSummary) {
    final game = Game.fromGameSummary(gameSummary);
    if (game.gameId != null) {
      game.userActions = UserGameActions(
        isSaved: savedGames.contains(game.gameId),
        isRated: ratedGames.contains(game.gameId),
        isHidden: hiddenGames.contains(game.gameId),
        userRating: userRatings[game.gameId],
      );
    }
    return game;
  }

  void processUserGameInfo(GameDetailWithUserInfo gameWithUserInfo) {
    final gameId = gameWithUserInfo.gameDetails.id;
    if (gameWithUserInfo.userActions != null) {
      if (gameWithUserInfo.userActions!.isSaved ?? false) {
        savedGames.add(gameId);
      }
      if (gameWithUserInfo.userActions!.isRated ?? false) {
        ratedGames.add(gameId);
      }
      if (gameWithUserInfo.userActions!.isHidden ?? false) {
        hiddenGames.add(gameId);
      }
      if (gameWithUserInfo.userActions!.userRating != null) {
        userRatings[gameId] = gameWithUserInfo.userActions!.userRating!;
      }
    }
  }

  // Belirli bir bölüm için veri yükleyen metot
  Future<void> loadSpecificSection(List<int> popularityTypeIds) async {
    try {
      isLoadingMoreSections = true;
      
      // Belirtilen popülerlik tipleri için oyunları yükle
      for (final popularityType in popularityTypeIds) {
        if (!popularityTypeGames.containsKey(popularityType)) {
          final response = await _gameRepository.fetchGamesByPopularityTypeWithUserInfo(
            popularityType: popularityType,
          );
          
          // Store games with user info
          final gamesWithUserInfo = response.content;
          popularityTypeGames[popularityType] = gamesWithUserInfo;
          
          // Process user-specific information
          for (final gameWithUser in gamesWithUserInfo) {
            processUserGameInfo(gameWithUser);
          }
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
    this.popularGameByVisits = popularGameByVisits;
  }

  Future<void> loadData() async {
    if (_isInitialized) return;

    try {
      // Use the new endpoints that include user info
      if (newReleases.isEmpty) {
        final newReleasesResponse = await _gameRepository.fetchNewReleasesWithUserInfo();
        newReleases = newReleasesResponse.content.map((gameWithUser) {
          // Store user-specific information
          processUserGameInfo(gameWithUser);
          return gameWithUser.gameDetails;
        }).toList();
      }
      
      if (topRatedGames.isEmpty) {
        final topRatedResponse = await _gameRepository.fetchTopRatedGamesWithUserInfo();
        topRatedGames = topRatedResponse.content.map((gameWithUser) {
          // Store user-specific information
          processUserGameInfo(gameWithUser);
          return gameWithUser.gameDetails;
        }).toList();
      }
      
      if (comingSoonGames.isEmpty) {
        final comingSoonResponse = await _gameRepository.fetchComingSoonWithUserInfo();
        comingSoonGames = comingSoonResponse.content.map((gameWithUser) {
          // Store user-specific information
          processUserGameInfo(gameWithUser);
          return gameWithUser.gameDetails;
        }).toList();
      }
      
      if (randomGame == null && newReleases.isNotEmpty) {
        randomGame = newReleases.first;
      }

      if (popularGameByVisits == null && SplashScreen.visitsPopularityTypeId != null) {
        // For now, keep using the old endpoint for this specific case
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

  // Get user rating for a game
  int? getUserRating(int gameId) {
    return userRatings[gameId];
  }

  // Check if a game is saved
  bool isGameSaved(int gameId) {
    print('isGameSaved - Game ID: $gameId, Result: ${savedGames.contains(gameId)}');
    print('isGameSaved - savedGames: $savedGames');
    return savedGames.contains(gameId);
  }

  // Check if a game is rated
  bool isGameRated(int gameId) {
    return ratedGames.contains(gameId);
  }

  // Check if a game is hidden
  bool isGameHidden(int gameId) {
    return hiddenGames.contains(gameId);
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
        if (!popularityTypeGames.containsKey(popularityType)) {
          final response = await _gameRepository.fetchGamesByPopularityTypeWithUserInfo(
            popularityType: popularityType,
          );
          
          // Store games with user info
          final gamesWithUserInfo = response.content;
          popularityTypeGames[popularityType] = gamesWithUserInfo;
          
          // Process user-specific information
          for (final gameWithUser in gamesWithUserInfo) {
            processUserGameInfo(gameWithUser);
          }
        }
      }
      
      _currentBatchIndex++;
    } catch (e) {
      error = e.toString();
      print('Error loading more sections: $e');
    } finally {
      isLoadingMoreSections = false;
    }
  }

  bool get hasMoreSections => _currentBatchIndex < _popularityTypeBatches.length;

  String getPopularityTypeTitle(int popularityType) {
    return popularityTypeTitles[popularityType] ?? 'Popular Games';
  }

  // Add this method to update game save state
  void updateGameSaveState(int gameId, bool isSaved) {
    if (isSaved) {
      savedGames.add(gameId);
    } else {
      savedGames.remove(gameId);
    }

    // Update in popularity type games
    for (var games in popularityTypeGames.values) {
      for (var gameWithUser in games) {
        if (gameWithUser.gameDetails.id == gameId) {
          final updatedActions = gameWithUser.userActions?.copyWith(isSaved: isSaved) ?? 
              UserGameActions(isSaved: isSaved);
          gameWithUser = GameDetailWithUserInfo(
            gameDetails: gameWithUser.gameDetails,
            userActions: updatedActions,
          );
        }
      }
    }

    // Update in other lists
    void updateGameInList(List<GameSummary> list) {
      for (var game in list) {
        if (game.id == gameId) {
          final gameWithActions = getGameWithUserActions(game);
          gameWithActions.userActions = UserGameActions(
            isSaved: isSaved,
            isRated: gameWithActions.userActions?.isRated,
            isHidden: gameWithActions.userActions?.isHidden,
            userRating: gameWithActions.userActions?.userRating,
          );
        }
      }
    }

    updateGameInList(newReleases);
    updateGameInList(topRatedGames);
    updateGameInList(comingSoonGames);
    
    print('Game save state updated - Game ID: $gameId, isSaved: $isSaved');
    print('Current saved games: $savedGames');
  }
} 