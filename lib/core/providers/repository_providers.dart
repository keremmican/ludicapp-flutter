import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/repository/library_repository.dart';

// Provider for GameRepository
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

// Provider for LibraryRepository
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
}); 