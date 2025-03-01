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
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  static ProfileResponse? _profileData;
  static List<NameIdResponse>? _popularityTypes;
  static int? _visitsPopularityTypeId;

  static ProfileResponse? get profileData => _profileData;
  static List<NameIdResponse>? get popularityTypes => _popularityTypes;
  static int? get visitsPopularityTypeId => _visitsPopularityTypeId;
  
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
  final ApiService _apiService = ApiService();
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
    // Fetch popularity types first
    final popularityTypesResponse = await _gameRepository.getPopularityTypes()
        .timeout(const Duration(seconds: 5));
    
    SplashScreen.popularityTypes = popularityTypesResponse;

    // Fetch data with timeout
    final newReleasesResponse = await _gameRepository.fetchNewReleases()
        .timeout(const Duration(seconds: 5));
    
    final topRatedResponse = await _gameRepository.fetchTopRatedGames()
        .timeout(const Duration(seconds: 5));

    final comingSoonResponse = await _gameRepository.fetchComingSoon()
        .timeout(const Duration(seconds: 5));

    // Fetch game by visits popularity type if available
    GameSummary? popularGameByVisits;
    if (SplashScreen.visitsPopularityTypeId != null) {
      popularGameByVisits = await _gameRepository.getSingleGameByPopularityType(
        SplashScreen.visitsPopularityTypeId!
      ).timeout(const Duration(seconds: 5));

      // Immediately preload the main game cover image if available
      if (popularGameByVisits?.coverUrl != null && popularGameByVisits!.coverUrl!.startsWith('http')) {
        try {
          final mainGameImageProvider = NetworkImage(popularGameByVisits.coverUrl!);
          await precacheImage(mainGameImageProvider, context);
        } catch (e) {
          developer.log('Failed to preload main game cover: ${e.toString()}');
        }
      }
    }

    // Initialize HomeController with fetched data
    _homeController.setInitialData(
      newReleases: newReleasesResponse.content,
      topRatedGames: topRatedResponse.content,
      comingSoonGames: comingSoonResponse.content,
      popularGameByVisits: popularGameByVisits,
    );

    // Preload only essential images for initial view
    // Preload showcase game and first few games from each initial section
    final imagesToPreload = <String>[];
    
    // Add showcase game image
    if (popularGameByVisits?.coverUrl != null && popularGameByVisits!.coverUrl!.startsWith('http')) {
      imagesToPreload.add(popularGameByVisits!.coverUrl!);
    }
    
    // Add first 3 images from new releases
    for (int i = 0; i < min(3, newReleasesResponse.content.length); i++) {
      final game = newReleasesResponse.content[i];
      if (game.coverUrl != null && game.coverUrl!.startsWith('http')) {
        imagesToPreload.add(game.coverUrl!);
      }
    }
    
    // Add first 3 images from top rated
    for (int i = 0; i < min(3, topRatedResponse.content.length); i++) {
      final game = topRatedResponse.content[i];
      if (game.coverUrl != null && game.coverUrl!.startsWith('http')) {
        imagesToPreload.add(game.coverUrl!);
      }
    }
    
    // Add first 3 images from coming soon
    for (int i = 0; i < min(3, comingSoonResponse.content.length); i++) {
      final game = comingSoonResponse.content[i];
      if (game.coverUrl != null && game.coverUrl!.startsWith('http')) {
        imagesToPreload.add(game.coverUrl!);
      }
    }
    
    // Preload images in parallel
    final preloadFutures = <Future>[];
    for (final imageUrl in imagesToPreload) {
      try {
        final imageProvider = NetworkImage(imageUrl);
        preloadFutures.add(precacheImage(imageProvider, context));
      } catch (e) {
        developer.log('Failed to preload image: ${e.toString()}');
      }
    }
    
    // Wait for all preloads to complete or timeout after 3 seconds
    await Future.wait(preloadFutures)
        .timeout(const Duration(seconds: 3), onTimeout: () {
      developer.log('Image preloading timed out, continuing with available images');
      return [];
    });
  }

  Future<void> _loadUserProfile() async {
    SplashScreen.profileData = await _userRepository.fetchUserProfile();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize categories first since it's critical
      await _initializeCategories();

      // Then load user profile and initial data in parallel
      await Future.wait([
        _loadInitialData(),
        _loadUserProfile(),
      ]);

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