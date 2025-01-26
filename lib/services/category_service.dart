import 'package:ludicapp/services/model/response/game_category.dart';
import 'package:ludicapp/services/repository/game_repository.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final GameRepository _gameRepository = GameRepository();
  
  List<GameCategory>? _genres;
  List<GameCategory>? _themes;
  
  bool get isInitialized => _genres != null && _themes != null;

  Future<void> initialize() async {
    if (isInitialized) return;
    
    try {
      _genres = await _gameRepository.fetchGenres();
      _themes = await _gameRepository.fetchThemes();
    } catch (e) {
      print('Error initializing categories: $e');
      rethrow;
    }
  }

  List<GameCategory> get genres => _genres ?? [];
  List<GameCategory> get themes => _themes ?? [];
} 