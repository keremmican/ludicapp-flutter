import 'package:flutter/material.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/category_service.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';
import 'package:ludicapp/services/repository/auth_repository.dart';
import 'package:ludicapp/services/repository/user_repository.dart';
import 'package:ludicapp/models/profile_response.dart';
import 'package:ludicapp/models/user_light_response.dart';
import 'package:dio/dio.dart';
import 'package:ludicapp/models/user_status.dart';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/model/response/name_id_response.dart';
import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';
import 'package:ludicapp/services/model/response/paged_game_with_user_response.dart';
import 'package:ludicapp/services/model/response/library_summary_response.dart';
import 'dart:math';
import 'package:ludicapp/services/repository/library_repository.dart';
import 'package:ludicapp/services/token_service.dart';

class SplashScreen extends StatefulWidget {
  static ProfileResponse? _profileData;
  static List<NameIdResponse>? _popularityTypes;
  static int? _visitsPopularityTypeId;
  static List<LibrarySummaryResponse>? _librarySummaries;

  static ProfileResponse? get profileData => _profileData;
  static List<NameIdResponse>? get popularityTypes => _popularityTypes;
  static int? get visitsPopularityTypeId => _visitsPopularityTypeId;
  static List<LibrarySummaryResponse>? get librarySummaries => _librarySummaries;
  
  static set profileData(ProfileResponse? value) {
    _profileData = value;
  }

  static set popularityTypes(List<NameIdResponse>? value) {
    _popularityTypes = value;
    if (value != null) {
      final visitsType = value.firstWhere(
        (type) => type.name == "Visits",
        orElse: () => value.first,
      );
      _visitsPopularityTypeId = visitsType.id;
    }
  }

  static set librarySummaries(List<LibrarySummaryResponse>? value) {
    _librarySummaries = value;
  }

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GameRepository _gameRepository = GameRepository();
  final CategoryService _categoryService = CategoryService();
  final HomeController _homeController = HomeController();
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final LibraryRepository _libraryRepository = LibraryRepository();
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  bool _isLoading = true;
  String? _errorMessage;
  ImageProvider? _backgroundImage;
  ImageProvider? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _initializeCategories() async {
    try {
      if (!_categoryService.isInitialized) {
        await _categoryService.initialize();
      }
    } catch (e) {
      // Continue even if there's an error, not critical
    }
  }

  Future<void> _loadInitialData() async {
    try {
      print('Loading user profile and library data...');
      // Önce profil verilerini yükle
      SplashScreen.profileData = await _userRepository.fetchUserProfile();
      print('Profile data loaded: ${SplashScreen.profileData?.username}');

      // Sonra library verilerini yükle
      final userId = await _tokenService.getUserId();
      final librarySummaries = await _libraryRepository.getAllLibrarySummaries(
        userId: userId.toString(),
      );
      SplashScreen.librarySummaries = librarySummaries;
      print('Library summaries loaded: ${librarySummaries.length} items');

      // Popularity types'ı yükle
      final popularityTypesResponse = await _gameRepository.getPopularityTypes();
      SplashScreen.popularityTypes = popularityTypesResponse;
      print('Popularity types loaded');

      // Diğer verileri yükle
      final newReleasesResponse = await _gameRepository.fetchNewReleasesWithUserInfo();
      final topRatedResponse = await _gameRepository.fetchTopRatedGamesWithUserInfo();
      final comingSoonResponse = await _gameRepository.fetchComingSoonWithUserInfo();
      print('Game lists loaded');

      GameSummary? popularGameByVisits;
      if (SplashScreen.visitsPopularityTypeId != null) {
        final popularGameResponse = await _gameRepository.getSingleGameByPopularityTypeWithUserInfo(
          SplashScreen.visitsPopularityTypeId!
        );

        _homeController.processUserGameInfo(popularGameResponse);
        popularGameByVisits = popularGameResponse.gameDetails;

        if (popularGameByVisits?.coverUrl != null && 
            popularGameByVisits!.coverUrl!.startsWith('http')) {
          try {
            final mainGameImageProvider = NetworkImage(popularGameByVisits.coverUrl!);
            await precacheImage(mainGameImageProvider, context);
          } catch (e) {
            print('Failed to preload main game cover: ${e.toString()}');
          }
        }
      }

      _homeController.setInitialData(
        newReleases: newReleasesResponse.content.map((item) {
          _homeController.processUserGameInfo(item);
          return item.gameDetails;
        }).toList(),
        topRatedGames: topRatedResponse.content.map((item) {
          _homeController.processUserGameInfo(item);
          return item.gameDetails;
        }).toList(),
        comingSoonGames: comingSoonResponse.content.map((item) {
          _homeController.processUserGameInfo(item);
          return item.gameDetails;
        }).toList(),
        popularGameByVisits: popularGameByVisits,
      );

      // Önemli resimleri önceden yükle
      final imagesToPreload = <String>[];
      
      if (popularGameByVisits?.coverUrl != null && 
          popularGameByVisits!.coverUrl!.startsWith('http')) {
        imagesToPreload.add(popularGameByVisits.coverUrl!);
      }
      
      for (int i = 0; i < min(3, newReleasesResponse.content.length); i++) {
        final game = newReleasesResponse.content[i].gameDetails;
        if (game.coverUrl != null && game.coverUrl!.startsWith('http')) {
          imagesToPreload.add(game.coverUrl!);
        }
      }
      
      for (int i = 0; i < min(3, topRatedResponse.content.length); i++) {
        final game = topRatedResponse.content[i].gameDetails;
        if (game.coverUrl != null && game.coverUrl!.startsWith('http')) {
          imagesToPreload.add(game.coverUrl!);
        }
      }
      
      for (int i = 0; i < min(3, comingSoonResponse.content.length); i++) {
        final game = comingSoonResponse.content[i].gameDetails;
        if (game.coverUrl != null && game.coverUrl!.startsWith('http')) {
          imagesToPreload.add(game.coverUrl!);
        }
      }
      
      await Future.wait(imagesToPreload.map((imageUrl) {
        try {
          final imageProvider = NetworkImage(imageUrl);
          return precacheImage(imageProvider, context);
        } catch (e) {
          print('Failed to preload image: ${e.toString()}');
          return Future.value();
        }
      })).timeout(const Duration(seconds: 3), onTimeout: () {
        print('Image preloading timed out, continuing with available images');
        return [];
      });

      print('All initial data loaded successfully');
    } catch (e) {
      print('Error in _loadInitialData: $e');
      rethrow;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    print('Starting to load all data...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize categories first since it's critical
      print('Initializing categories...');
      await _initializeCategories();

      // Load initial data which now includes user profile loading
      print('Loading initial data...');
      await _loadInitialData();

      print('All data loaded successfully');

      if (!mounted) return;

      if (SplashScreen.profileData != null) {
        switch (SplashScreen.profileData!.userStatus) {
          case UserStatus.ACTIVE:
            Navigator.of(context).pushReplacementNamed('/main');
            break;
          case UserStatus.ONBOARDING:
            Navigator.of(context).pushReplacementNamed('/onboarding');
            break;
          case UserStatus.BANNED:
            Navigator.of(context).pushReplacementNamed('/banned');
            break;
          case UserStatus.DELETED:
            try {
              await _apiService.post('/api/auth/reactivate-account', {});
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/main');
            } catch (e) {
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/landing');
            }
            break;
        }
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/landing');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic error) {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      if (error is DioException) {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            _errorMessage = 'Connection timeout';
            break;
          case DioExceptionType.connectionError:
            _errorMessage = 'No internet connection';
            break;
          case DioExceptionType.badResponse:
            if (error.response?.statusCode == 401) {
              Navigator.of(context).pushReplacementNamed('/landing');
              return;
            } else if (error.response?.statusCode == 500) {
              _errorMessage = 'Server error';
            } else {
              _errorMessage = 'Connection error';
            }
            break;
          default:
            _errorMessage = 'Connection error';
            break;
        }
      } else {
        _errorMessage = 'An unexpected error occurred';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/app_logo_2.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ] else if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 