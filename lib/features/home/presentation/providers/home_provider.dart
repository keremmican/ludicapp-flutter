import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludicapp/features/home/presentation/providers/home_state.dart';
import 'package:ludicapp/services/repository/game_repository.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(GameRepository());
});

class HomeNotifier extends StateNotifier<HomeState> {
  final GameRepository _gameRepository;

  HomeNotifier(this._gameRepository) : super(const HomeState()) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final newReleasesResponse = await _gameRepository.fetchNewReleases();
      final topRatedResponse = await _gameRepository.fetchTopRatedGames();

      state = state.copyWith(
        newReleases: newReleasesResponse.content,
        topRatedGames: topRatedResponse.content,
        randomGame: newReleasesResponse.content.isNotEmpty ? newReleasesResponse.content.first : null,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }
} 