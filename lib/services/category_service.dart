import 'package:ludicapp/services/model/response/game_category.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/api_service.dart';
import 'dart:convert';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final GameRepository _gameRepository = GameRepository();
  
  bool isInitialized = false;
  List<GameCategory> _genres = [];
  List<GameCategory> _themes = [];
  List<Map<String, dynamic>> _platforms = [];

  List<GameCategory> get genres => _genres;
  List<GameCategory> get themes => _themes;
  List<Map<String, dynamic>> get platforms => _platforms;

  Future<void> initialize() async {
    try {
      final apiService = ApiService();
      
      // Fetch genres
      final genresResponse = await apiService.get('/games/get-genres');
      final List<dynamic> genresData = genresResponse.data is String 
          ? json.decode(genresResponse.data as String)
          : genresResponse.data as List<dynamic>;
      
      _genres = genresData.map((g) => GameCategory.fromJson(g as Map<String, dynamic>)).toList();

      // Fetch themes
      final themesResponse = await apiService.get('/games/get-themes');
      final List<dynamic> themesData = themesResponse.data is String 
          ? json.decode(themesResponse.data as String)
          : themesResponse.data as List<dynamic>;
      
      _themes = themesData.map((t) => GameCategory.fromJson(t as Map<String, dynamic>)).toList();

      // Use static platforms instead of fetching from API
      _platforms = [
        {'id': 14, 'name': 'Mac'},
        {'id': 167, 'name': 'PlayStation 5'},
        {'id': 56, 'name': 'PC (Microsoft Windows)'},
        {'id': 130, 'name': 'Nintendo Switch'},
        {'id': 169, 'name': 'Xbox Series X|S'},
        {'id': 34, 'name': 'Android'},
        {'id': 48, 'name': 'PlayStation 4'},
        {'id': 49, 'name': 'Xbox One'},
        {'id': 39, 'name': 'iOS'},
        {'id': 3, 'name': 'Linux'},
      ];

      isInitialized = true;
    } catch (e) {
      print('Error initializing categories: $e');
      rethrow;
    }
  }

  @deprecated
  Future<void> setPlatforms(List<Map<String, dynamic>> platforms) async {
    _platforms = platforms;
  }
} 