import 'package:flutter/material.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/category_service.dart';
import 'package:ludicapp/features/home/presentation/controller/home_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GameRepository _gameRepository = GameRepository();
  final CategoryService _categoryService = CategoryService();
  final HomeController _homeController = HomeController();
  bool _isLoading = false;
  ImageProvider? _backgroundImage;
  ImageProvider? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Başlatma işlemlerini ve veri çekme işlemlerini paralel yap
      await Future.wait([
        _initializeCategories(), // Kategorileri yükle
        _loadInitialData(), // Ana sayfa verilerini yükle
      ]);

      // Ana sayfaya git
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      print('Error during data loading: $e');
      // Even if there's an error, continue to main layout after a short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    }
  }

  Future<void> _initializeCategories() async {
    if (!_categoryService.isInitialized) {
      try {
        await _categoryService.initialize();
      } catch (e) {
        print('Error loading categories: $e');
        // Hata olsa bile devam et, kritik değil
      }
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

    print('Data fetched successfully');

    // Her listeden ilk 4 resmi al
    final priorityImages = [
      ...newReleasesResponse.content.take(4).map((game) => game.coverUrl),
      ...topRatedResponse.content.take(4).map((game) => game.coverUrl),
      ...comingSoonResponse.content.take(4).map((game) => game.coverUrl),
    ].where((url) => url != null).cast<String>();

    print('Starting to preload ${priorityImages.length} priority images');

    // Öncelikli resimleri yükle
    for (final imageUrl in priorityImages) {
      if (imageUrl?.startsWith('http') ?? false) {
        try {
          final imageProvider = NetworkImage(imageUrl);
          await precacheImage(imageProvider, context);
          print('Preloaded priority image: $imageUrl');
        } catch (e) {
          print('Failed to preload priority image: $imageUrl');
        }
      }
    }

    print('Priority images preloaded');

    // Kısa bir bekleme ekleyelim ki kullanıcı logo'yu görebilsin
    await Future.delayed(const Duration(seconds: 1));

    // Geri kalan resimleri arka planda yükle
    final remainingImages = [
      ...newReleasesResponse.content.skip(4).map((game) => game.coverUrl),
      ...topRatedResponse.content.skip(4).map((game) => game.coverUrl),
      ...comingSoonResponse.content.skip(4).map((game) => game.coverUrl),
    ].where((url) => url != null).cast<String>();

    print('Starting to preload ${remainingImages.length} remaining images in background');

    for (final imageUrl in remainingImages) {
      if (imageUrl?.startsWith('http') ?? false) {
        try {
          final imageProvider = NetworkImage(imageUrl);
          precacheImage(imageProvider, context); // await kullanmıyoruz
          print('Started preloading background image: $imageUrl');
        } catch (e) {
          print('Failed to preload background image: $imageUrl');
        }
      }
    }
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final response = await _gameRepository.fetchNewReleases();
      if (response.content.isNotEmpty) {
        final game = response.content.first;
        final coverUrl = game.coverUrl;
        
        if (coverUrl?.startsWith('http') ?? false) {
          setState(() {
            _isLoading = true;
          });
          
          final imageProvider = NetworkImage(coverUrl!);
          await precacheImage(imageProvider, context);
          
          if (mounted) {
            setState(() {
              _backgroundImage = imageProvider;
              _isLoading = false;
            });
          }
        }
      }
    } catch (error) {
      print('Error loading background image: $error');
    }
  }

  Future<void> _loadLogo() async {
    try {
      final response = await _gameRepository.fetchTopRatedGames();
      if (response.content.isNotEmpty) {
        final game = response.content.first;
        final coverUrl = game.coverUrl;
        
        if (coverUrl?.startsWith('http') ?? false) {
          setState(() {
            _isLoading = true;
          });
          
          final imageProvider = NetworkImage(coverUrl!);
          await precacheImage(imageProvider, context);
          
          if (mounted) {
            setState(() {
              _logoImage = imageProvider;
              _isLoading = false;
            });
          }
        }
      }
    } catch (error) {
      print('Error loading logo image: $error');
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