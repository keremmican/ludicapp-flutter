import 'package:flutter/material.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ludicapp/services/repository/game_repository.dart';
import 'package:ludicapp/services/category_service.dart';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/services/model/response/game_category.dart';
import 'dart:convert';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  
  final _gameRepository = GameRepository();
  final _categoryService = CategoryService();
  final _apiService = ApiService();
  final _tokenService = TokenService();
  
  final Set<int> _selectedPlatformIds = {};
  final Set<int> _selectedGenreIds = {};
  final Set<int> _selectedThemeIds = {};
  List<Map<String, dynamic>> _platforms = [];
  List<GameCategory> _genres = [];
  List<GameCategory> _themes = [];

  // Static platforms for onboarding
  final List<Map<String, dynamic>> _staticPlatforms = [
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

  bool get _canProceedFromPlatforms => _selectedPlatformIds.length >= 1;
  bool get _canProceedFromGenres => _selectedGenreIds.length >= 3;
  bool get _canProceedFromThemes => _selectedThemeIds.length >= 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load categories (genres and themes)
      if (!_categoryService.isInitialized) {
        await _categoryService.initialize();
      }

      if (mounted) {
        setState(() {
          _genres = _categoryService.genres;
          _themes = _categoryService.themes;
          _platforms = _staticPlatforms;
        });
      }
    } catch (e) {
      print('Error loading onboarding data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load data')),
        );
      }
    }
  }

  void _nextPage() {
    bool canProceed = false;
    String message = '';

    switch (_currentPage) {
      case 0:
        canProceed = _canProceedFromPlatforms;
        message = 'Please select at least 1 platform';
        break;
      case 1:
        canProceed = _canProceedFromGenres;
        message = 'Please select at least 3 genres';
        break;
      case 2:
        canProceed = _canProceedFromThemes;
        message = 'Please select at least 3 themes';
        break;
      case 3:
        canProceed = true;
        break;
    }

    if (!canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Last page - Update user status and navigate to main
    _updateUserStatusAndNavigate();
  }

  Future<void> _updateUserStatusAndNavigate() async {
    try {
      final userId = await _tokenService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _apiService.post(
        '/v1/users/complete-onboarding',
        {
          'userId': userId,
          'genres': _selectedGenreIds.map((id) => id.toString()).toList(),
          'platforms': _selectedPlatformIds.map((id) => id.toString()).toList(),
          'themes': _selectedThemeIds.map((id) => id.toString()).toList(),
        },
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
        );
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete onboarding')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Spacer(),
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: 4,
                      effect: ExpandingDotsEffect(
                        activeDotColor: Theme.of(context).colorScheme.primary,
                        dotColor: Colors.black26,
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 8,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPlatformsPage(),
                    _buildGenresPage(),
                    _buildThemesPage(),
                    _buildWelcomePage(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == 3 ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gaming Platforms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 1 gaming platform',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _platforms.map((platform) => _buildChip(
              platform['name'] as String,
              _selectedPlatformIds.contains(platform['id']),
              () {
                setState(() {
                  if (_selectedPlatformIds.contains(platform['id'])) {
                    _selectedPlatformIds.remove(platform['id']);
                  } else {
                    _selectedPlatformIds.add(platform['id']);
                  }
                });
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenresPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Favorite Genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 3 favorite game genres',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) => _buildChip(
              genre.name,
              _selectedGenreIds.contains(genre.id),
              () {
                setState(() {
                  if (_selectedGenreIds.contains(genre.id)) {
                    _selectedGenreIds.remove(genre.id);
                  } else {
                    _selectedGenreIds.add(genre.id);
                  }
                });
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Themes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least 3 preferred game themes',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _themes.map((theme) => _buildChip(
              theme.name,
              _selectedThemeIds.contains(theme.id),
              () {
                setState(() {
                  if (_selectedThemeIds.contains(theme.id)) {
                    _selectedThemeIds.remove(theme.id);
                  } else {
                    _selectedThemeIds.add(theme.id);
                  }
                });
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 100,
          ),
          const SizedBox(height: 32),
          const Text(
            'All Set!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your gaming profile has been created. Get ready to discover new games and connect with other gamers!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppTheme.surfaceDark,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
} 