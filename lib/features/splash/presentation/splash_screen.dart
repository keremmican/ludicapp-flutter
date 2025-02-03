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
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  static ProfileResponse? get profileData => _SplashScreenState._profileData;

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GameRepository _gameRepository = GameRepository();
  final CategoryService _categoryService = CategoryService();
  final HomeController _homeController = HomeController();
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _hasError = false;
  ImageProvider? _backgroundImage;
  ImageProvider? _logoImage;
  static ProfileResponse? _profileData;

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
    // Fetch data with timeout
    final newReleasesResponse = await _gameRepository.fetchNewReleases()
        .timeout(const Duration(seconds: 5));
    
    final topRatedResponse = await _gameRepository.fetchTopRatedGames()
        .timeout(const Duration(seconds: 5));

    final comingSoonResponse = await _gameRepository.fetchComingSoon()
        .timeout(const Duration(seconds: 5));

    // Initialize HomeController with fetched data
    _homeController.setInitialData(
      newReleases: newReleasesResponse.content,
      topRatedGames: topRatedResponse.content,
      comingSoonGames: comingSoonResponse.content,
    );

    // Her listeden ilk 4 resmi al
    final priorityImages = [
      ...newReleasesResponse.content.take(4).map((game) => game.coverUrl),
      ...topRatedResponse.content.take(4).map((game) => game.coverUrl),
      ...comingSoonResponse.content.take(4).map((game) => game.coverUrl),
    ].where((url) => url != null).cast<String>();

    // Öncelikli resimleri yükle
    for (final imageUrl in priorityImages) {
      if (imageUrl?.startsWith('http') ?? false) {
        try {
          final imageProvider = NetworkImage(imageUrl);
          await precacheImage(imageProvider, context);
        } catch (e) {
          // Ignore image loading errors
        }
      }
    }

    // Kısa bir bekleme ekleyelim ki kullanıcı logo'yu görebilsin
    await Future.delayed(const Duration(seconds: 1));

    // Geri kalan resimleri arka planda yükle
    final remainingImages = [
      ...newReleasesResponse.content.skip(4).map((game) => game.coverUrl),
      ...topRatedResponse.content.skip(4).map((game) => game.coverUrl),
      ...comingSoonResponse.content.skip(4).map((game) => game.coverUrl),
    ].where((url) => url != null).cast<String>();

    for (final imageUrl in remainingImages) {
      if (imageUrl?.startsWith('http') ?? false) {
        try {
          final imageProvider = NetworkImage(imageUrl);
          precacheImage(imageProvider, context);
        } catch (e) {
          // Ignore image loading errors
        }
      }
    }
  }

  Future<void> _loadUserProfile() async {
    _profileData = await _userRepository.fetchUserProfile();
  }

  Future<void> _loadData() async {
    try {
      // Tüm veri yükleme işlemlerini paralel yap
      await Future.wait([
        _initializeCategories(),
        _loadInitialData(),
        _loadUserProfile(),
      ]);

      if (!mounted) return;

      if (_profileData != null) {
        switch (_profileData!.userStatus) {
          case UserStatus.ACTIVE:
            Navigator.of(context).pushReplacementNamed('/main');
            break;
          case UserStatus.ONBOARDING:
            try {
              await _apiService.get('/games/get-platforms');
              Navigator.of(context).pushReplacementNamed('/onboarding');
            } catch (e) {
              setState(() {
                _hasError = true;
              });
            }
            break;
          case UserStatus.BANNED:
            Navigator.of(context).pushReplacementNamed('/banned');
            break;
          case UserStatus.DELETED:
            try {
              await _apiService.post('/api/auth/reactivate-account', {});
              Navigator.of(context).pushReplacementNamed('/main');
            } catch (e) {
              Navigator.of(context).pushReplacementNamed('/landing');
            }
            break;
        }
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/landing');
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 401) {
          Navigator.of(context).pushReplacementNamed('/landing');
        } else {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
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
            if (_hasError) ...[
              const Text(
                'Connection error',
                style: TextStyle(color: Colors.red),
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
            ] else
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