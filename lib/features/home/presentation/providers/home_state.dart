import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';

part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    @Default([]) List<GameSummary> newReleases,
    @Default([]) List<GameSummary> topRatedGames,
    GameSummary? randomGame,
    @Default(false) bool isLoading,
    String? error,
  }) = _HomeState;
} 