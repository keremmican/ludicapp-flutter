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
      
      // Fetch themes
      final themesResponse = await apiService.get('/games/get-themes');
      final List<dynamic> themesData = themesResponse.data is String 
          ? json.decode(themesResponse.data as String)
          : themesResponse.data as List<dynamic>;

      // Fetch platforms
      final platformsResponse = await apiService.get('/games/get-platforms');
      final List<dynamic> platformsData = platformsResponse.data is String 
          ? json.decode(platformsResponse.data as String)
          : platformsResponse.data as List<dynamic>;

      _genres = genresData
          .map((genre) => GameCategory.fromJson(genre as Map<String, dynamic>))
          .toList();

      _themes = themesData
          .map((theme) => GameCategory.fromJson(theme as Map<String, dynamic>))
          .toList();

      _platforms = platformsData.map((p) => {
        'id': p['id'] as int,
        'name': p['name'] as String,
      }).toList();

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