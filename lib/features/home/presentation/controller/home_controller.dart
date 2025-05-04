import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/name_id_response.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/core/models/game.dart';
import 'package:ludicapp/services/model/response/user_game_info.dart';
import 'package:ludicapp/services/model/response/user_game_actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ludicapp/core/enums/play_status.dart';
import 'package:ludicapp/core/enums/completion_status.dart';

// ChangeNotifier'dan extend edelim
class HomeController extends ChangeNotifier {
  static final HomeController _instance = HomeController._internal();
  factory HomeController() => _instance;
  HomeController._internal();

  final GameRepository _gameRepository = GameRepository();
  final LibraryRepository _libraryRepository = LibraryRepository();

  List<GameSummary> newReleases = [];
  List<GameSummary> topRatedGames = [];
  List<GameSummary> comingSoonGames = [];
  GameSummary? randomGame;
  GameSummary? popularGameByVisits;
  Map<int, List<GameDetailWithUserInfo>> popularityTypeGames = {};
  bool isLoadingMoreSections = false;
  String? error;

  // User-specific information
  // Map<int, int> userRatings = {}; // gameId -> rating // Kaldırıldı
  Set<int> savedGames = {}; // gameIds that are saved
  // Set<int> ratedGames = {}; // gameIds that are rated // Kaldırıldı
  Set<int> hiddenGames = {}; // gameIds that are hidden
  Map<int, int?> gameRatings = {}; // Rating null olabilir
  Map<int, String?> gameComments = {}; // Comment null olabilir
  
  // Oyun durumlarını saklamak için yeni haritalar ekle
  Map<int, PlayStatus?> gamePlayStatuses = {}; // PlayStatus null olabilir
  Map<int, CompletionStatus?> gameCompletionStatuses = {}; // CompletionStatus null olabilir
  Map<int, int?> gamePlaytimes = {}; // Playtime null olabilir
  
  // savedGamesList değişkenini tanımlayalım
  List<Game> savedGamesList = [];
  
  bool _isInitialized = false;
  int _currentBatchIndex = 0;

  // Add list for currently playing games
  List<GameSummary> currentlyPlayingGames = [];

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
      final gameId = game.gameId!;
      game.userActions = UserGameActions(
        isSaved: savedGames.contains(gameId),
        isRated: isGameRated(gameId),
        isHidden: hiddenGames.contains(gameId),
        userRating: gameRatings[gameId],
        comment: gameComments[gameId],
        // Yeni alanları da ekle
        playStatus: gamePlayStatuses[gameId],
        completionStatus: gameCompletionStatuses[gameId],
        playtimeInMinutes: gamePlaytimes[gameId],
      );
    }
    return game;
  }

  void processUserGameInfo(GameDetailWithUserInfo gameWithUserInfo) {
    final gameId = gameWithUserInfo.gameDetails.id;
    if (gameWithUserInfo.userActions != null) {
      final actions = gameWithUserInfo.userActions!;
      
      if (actions.isSaved ?? false) {
        savedGames.add(gameId);
      }
      if (actions.isHidden ?? false) {
        hiddenGames.add(gameId);
      }
      if (actions.userRating != null) {
        gameRatings[gameId] = actions.userRating;
      }
      if (actions.comment != null) {
        gameComments[gameId] = actions.comment;
      }
      
      // Yeni eklenen alanları da sakla
      if (actions.playStatus != null) {
        gamePlayStatuses[gameId] = actions.playStatus;
      }
      if (actions.completionStatus != null) {
        gameCompletionStatuses[gameId] = actions.completionStatus;
      }
      if (actions.playtimeInMinutes != null) {
        gamePlaytimes[gameId] = actions.playtimeInMinutes;
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
    required List<GameSummary> currentlyPlayingGames,
    GameSummary? popularGameByVisits,
  }) {
    this.newReleases = newReleases;
    this.topRatedGames = topRatedGames;
    this.comingSoonGames = comingSoonGames;
    this.currentlyPlayingGames = currentlyPlayingGames;
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
    return gameRatings[gameId];
  }

  // Check if a game is saved
  bool isGameSaved(int gameId) {
    print('isGameSaved - Game ID: $gameId, Result: ${savedGames.contains(gameId)}');
    print('isGameSaved - savedGames: $savedGames');
    return savedGames.contains(gameId);
  }

  // Check if a game is rated
  bool isGameRated(int gameId) {
    return gameRatings.containsKey(gameId) && gameRatings[gameId] != null;
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
    notifyListeners();
  }

  // Rating durumunu güncelle (rating silme ve değiştirme dahil)
  void updateGameRatingState(int gameId, int? rating) {
    if (rating != null && rating > 0) {
      gameRatings[gameId] = rating;
    } else {
      gameRatings.remove(gameId);
    }
    notifyListeners();
    print('HomeController - Updated gameRating for $gameId: $rating');
  }

  // Update game comment
  void updateGameComment(int gameId, String? comment) {
    if (comment != null && comment.isNotEmpty) {
      gameComments[gameId] = comment;
    } else {
      gameComments.remove(gameId); // Yorum null veya boş ise kaldır
    }
    notifyListeners();
    print('HomeController - Updated comment for $gameId: $comment');
  }

  // Optional: Add methods to update the currentlyPlayingGames list 
  // if the modal needs to directly notify the controller.
  void addGameToCurrentlyPlaying(GameSummary game) {
    if (!currentlyPlayingGames.any((g) => g.id == game.id)) {
      currentlyPlayingGames.insert(0, game); // Add to beginning
      notifyListeners();
    }
  }

  void removeGameFromCurrentlyPlaying(int gameId) {
    final index = currentlyPlayingGames.indexWhere((g) => g.id == gameId);
    if (index != -1) {
      currentlyPlayingGames.removeAt(index);
      notifyListeners();
    }
  }

  // <-- Add method to update hidden state -->
  void updateGameHiddenState(int gameId, bool isHidden) {
    if (isHidden) {
      hiddenGames.add(gameId);
      // Hiding a game removes rating, comment, and saved status
      gameRatings.remove(gameId);
      gameComments.remove(gameId);
      savedGames.remove(gameId);
    } else {
      hiddenGames.remove(gameId);
    }
    notifyListeners();
  }
  
  // Update game play status
  void updateGamePlayStatus(int gameId, PlayStatus? playStatus) {
    // Global haritaya kaydet
    if (playStatus != null) {
      gamePlayStatuses[gameId] = playStatus;
    } else {
      gamePlayStatuses.remove(gameId);
    }
    
    // Popularity tipi oyunlarda güncelle
    for (var entry in popularityTypeGames.entries) {
      int popularityTypeId = entry.key;
      List<GameDetailWithUserInfo> games = entry.value;
      
      for (int i = 0; i < games.length; i++) {
        if (games[i].gameDetails.id == gameId && games[i].userActions != null) {
          // Yeni bir GameDetailWithUserInfo nesnesi oluştur
          popularityTypeGames[popularityTypeId]![i] = GameDetailWithUserInfo(
            gameDetails: games[i].gameDetails,
            userActions: games[i].userActions!.copyWith(playStatus: playStatus),
          );
        }
      }
    }
    
    notifyListeners();
    print('HomeController - Updated playStatus for $gameId: $playStatus');
  }
  
  // Update game completion status
  void updateGameCompletionStatus(int gameId, CompletionStatus? completionStatus) {
    // Global haritaya kaydet
    if (completionStatus != null) {
      gameCompletionStatuses[gameId] = completionStatus;
    } else {
      gameCompletionStatuses.remove(gameId);
    }
    
    // Popularity tipi oyunlarda güncelle
    for (var entry in popularityTypeGames.entries) {
      int popularityTypeId = entry.key;
      List<GameDetailWithUserInfo> games = entry.value;
      
      for (int i = 0; i < games.length; i++) {
        if (games[i].gameDetails.id == gameId && games[i].userActions != null) {
          // Yeni bir GameDetailWithUserInfo nesnesi oluştur
          popularityTypeGames[popularityTypeId]![i] = GameDetailWithUserInfo(
            gameDetails: games[i].gameDetails,
            userActions: games[i].userActions!.copyWith(completionStatus: completionStatus),
          );
        }
      }
    }
    
    notifyListeners();
    print('HomeController - Updated completionStatus for $gameId: $completionStatus');
  }
  
  // Update game playtime
  void updateGamePlaytime(int gameId, int? playtimeInMinutes) {
    // Global haritaya kaydet
    if (playtimeInMinutes != null) {
      gamePlaytimes[gameId] = playtimeInMinutes;
    } else {
      gamePlaytimes.remove(gameId);
    }
    
    // Popularity tipi oyunlarda güncelle
    for (var entry in popularityTypeGames.entries) {
      int popularityTypeId = entry.key;
      List<GameDetailWithUserInfo> games = entry.value;
      
      for (int i = 0; i < games.length; i++) {
        if (games[i].gameDetails.id == gameId && games[i].userActions != null) {
          // Yeni bir GameDetailWithUserInfo nesnesi oluştur
          popularityTypeGames[popularityTypeId]![i] = GameDetailWithUserInfo(
            gameDetails: games[i].gameDetails,
            userActions: games[i].userActions!.copyWith(playtimeInMinutes: playtimeInMinutes),
          );
        }
      }
    }
    
    notifyListeners();
    print('HomeController - Updated playtimeInMinutes for $gameId: $playtimeInMinutes');
  }
} 