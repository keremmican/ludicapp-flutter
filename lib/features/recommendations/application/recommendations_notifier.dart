import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/core/providers/repository_providers.dart'; // Varsayım: Provider'lar burada
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; // CardSwiperDirection için
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:math';  // Add this import for min() function

part 'recommendations_notifier.freezed.dart'; // build_runner ile oluşturulacak
part 'recommendations_notifier.g.dart';

@freezed
class RecommendationsState with _$RecommendationsState {
  const factory RecommendationsState({
    @Default([]) List<GameSummary> games,
    @Default(0) int currentCardIndex,
    @Default(false) bool isLoadingMore, // Daha fazla yükleme durumunu özel olarak yönetmek için
    @Default(false) bool noMoreGamesInitially, // Başlangıçta hiç oyun bulunamadığında işaretlemek için
    @Default(false) bool allGamesLoaded, // Yüklenecek başka oyun kalmadığında işaretlemek için
  }) = _RecommendationsState;
}

// @riverpod annotation'ını keepAlive: true ile ekliyoruz
@Riverpod(keepAlive: true)
class RecommendationsNotifier extends _$RecommendationsNotifier {
  late GameRepository _gameRepository;
  late LibraryRepository _libraryRepository;

  // Başlangıçta ve daha fazla yüklerken alınacak oyun sayısı
  final int _fetchCount = 10;
  final int _loadMoreCount = 5;
  // Daha fazla oyun yüklemeyi tetikleme eşiği
  final int _loadMoreThreshold = 3;

  @override
  FutureOr<RecommendationsState> build() async {
    _gameRepository = ref.watch(gameRepositoryProvider);
    _libraryRepository = ref.watch(libraryRepositoryProvider);

    // build metodundaki state kontrolüne artık gerek yok,
    // çünkü keepAlive state'i koruyacak ve build sadece ilk başta çalışacak.
    
    return await _loadInitialGames();
  }

  Future<RecommendationsState> _loadInitialGames() async {
    try {
      final games = await _gameRepository.fetchRandomGames(count: _fetchCount);
      if (games.isEmpty) {
        return const RecommendationsState(noMoreGamesInitially: true);
      }
      // Resimleri önbelleğe alma UI katmanında yapılmalı (BuildContext gerektiği için)
      return RecommendationsState(games: games);
    } catch (e, s) {
      print('İlk oyunları yüklerken hata oluştu: $e');
      // Hatayı yayarak AsyncNotifier'ın hata durumunu yönetmesine izin ver
      throw Exception('Öneriler yüklenemedi: $e');
    }
  }

  Future<void> loadMoreGames() async {
    final currentStateValue = state.value;
    // Ensure we can load more
    if (currentStateValue == null ||
        currentStateValue.isLoadingMore ||
        state.isLoading ||
        state.hasError ||
        currentStateValue.allGamesLoaded) {
      return;
    }

    // LOG: Before loading more
    print('BEFORE LOAD MORE - Current index: ${currentStateValue.currentCardIndex}');
    print('Current games count: ${currentStateValue.games.length}');
    for (int i = 0; i < min(3, currentStateValue.games.length); i++) {
      print('Game $i: ID=${currentStateValue.games[i].id}, Name=${currentStateValue.games[i].name}');
    }
    if (currentStateValue.games.length > 0) {
      final lastIdx = currentStateValue.games.length - 1;
      print('Last Game: ID=${currentStateValue.games[lastIdx].id}, Name=${currentStateValue.games[lastIdx].name}');
    }

    state = AsyncData(currentStateValue.copyWith(isLoadingMore: true));

    try {
      final newGames = await _gameRepository.fetchRandomGames(count: _loadMoreCount);
      
      // LOG: New games fetched
      print('NEW GAMES FETCHED: ${newGames.length}');
      for (int i = 0; i < min(3, newGames.length); i++) {
        print('New Game $i: ID=${newGames[i].id}, Name=${newGames[i].name}');
      }
      
      final currentGames = List<GameSummary>.from(currentStateValue.games); // Create a copy to be safe
      final allGames = [...currentGames, ...newGames];
      
      // Eğer yeni oyun gelmediyse, daha fazla oyun olmadığını işaretle
      final bool allLoaded = newGames.isEmpty;

      // LOG: After combining lists
      print('AFTER COMBINING - Total games: ${allGames.length}');
      for (int i = 0; i < min(3, allGames.length); i++) {
        print('Game $i: ID=${allGames[i].id}, Name=${allGames[i].name}');
      }
      if (allGames.length > 0) {
        final lastIdx = allGames.length - 1;
        print('Last Game: ID=${allGames[lastIdx].id}, Name=${allGames[lastIdx].name}');
      }
      print('Current card index will be: ${currentStateValue.currentCardIndex}');

      state = AsyncData(currentStateValue.copyWith(
        games: allGames,
        isLoadingMore: false,
        allGamesLoaded: allLoaded,
      ));
      
      // LOG: State updated
      print('STATE UPDATED with ${allGames.length} games');
    } catch (e) {
      print('Error loading more games: $e');
      state = AsyncData(currentStateValue.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _saveGameInternal(int gameId) async {
    try {
      bool success = await _libraryRepository.saveGame(gameId);
      if (success) {
        print('Oyun $gameId başarıyla kaydedildi!');
        // İsteğe bağlı: Başarı durumunu state'e yansıt veya UI geri bildirimi göster
      } else {
        print('Oyun $gameId kaydedilemedi.');
        // İsteğe bağlı: Başarısızlık durumunu state'e yansıt veya UI geri bildirimi göster
      }
    } catch (e) {
      print('Oyun $gameId kaydedilirken hata oluştu: $e');
      // İsteğe bağlı: Hata durumunu state'e yansıt veya UI geri bildirimi göster
    }
  }

  void swipe(int swipedCardIndex, CardSwiperDirection direction) {
    final currentStateValue = state.value;
    // Ensure state is loaded and index is valid
    if (currentStateValue == null || swipedCardIndex < 0) return;

    final games = currentStateValue.games;
    
    // LOG: Before swipe - Print first 3 games in list for comparison
    print('BEFORE SWIPE - Current index: ${currentStateValue.currentCardIndex}');
    for (int i = 0; i < min(3, games.length); i++) {
      print('Game $i: ID=${games[i].id}, Name=${games[i].name}');
    }
    print('...');
    if (games.length > swipedCardIndex) {
      print('Swiped Game: ID=${games[swipedCardIndex].id}, Name=${games[swipedCardIndex].name}');
    }

    // Save game if swiped right and index is within bounds
    if (direction == CardSwiperDirection.right && swipedCardIndex < games.length) {
      _saveGameInternal(games[swipedCardIndex].id);
    }

    // Update the currentCardIndex to point to the next card
    // Ensure the index doesn't go beyond the list bounds + 1 (to indicate end)
    final nextIndex = (swipedCardIndex + 1).clamp(0, games.length);
    
    // Update state *only* with the new index
    final newState = currentStateValue.copyWith(currentCardIndex: nextIndex);
    state = AsyncData(newState);
    
    // LOG: After swipe
    print('AFTER SWIPE - New index: $nextIndex');
  }

  void refreshGames() {
    // State'i yükleniyor durumuna getir ve build'i tekrar tetikle
    state = const AsyncLoading();
    ref.invalidateSelf(); // Bu, build() metodunun tekrar çalışmasını sağlar
  }
}

// Manuel provider tanımını kaldırıyoruz, çünkü @riverpod bunu otomatik yapacak 