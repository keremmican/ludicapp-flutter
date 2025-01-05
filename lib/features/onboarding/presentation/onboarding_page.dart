import 'package:flutter/material.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  bool _isEmailSelected = true; // Track if email is selected (false means phone is selected)
  
  // Form controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  
  // Selected platforms and genres
  final Set<String> _selectedPlatforms = {};
  final Set<String> _selectedGenres = {};

  // Platform options
  final List<String> _platforms = [
    'Steam',
    'Epic Games',
    'PlayStation',
    'Xbox',
    'Nintendo Switch',
    'Mobile'
  ];

  // Genre options
  final List<String> _genres = [
    'Action',
    'Adventure',
    'RPG',
    'Strategy',
    'Sports',
    'Racing',
    'Simulation',
    'Puzzle',
    'Horror',
    'Fighting'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 2) {
      // Complete onboarding
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main',
        (route) => false, // This removes all previous routes
      );
      return;
    }
    
    if (_currentPage == 0) {
      // Validate email/phone before proceeding
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (_currentPage == 0) {
      Navigator.pop(context);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _previousPage,
                  ),
                  const Spacer(),
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppTheme.accentColor,
                      dotColor: Colors.grey[800]!,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                  _buildEmailPage(),
                  _buildUsernamePage(),
                  _buildPreferencesPage(),
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
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? 'Get Started' : 'Continue',
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
    );
  }

  Widget _buildEmailPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to continue',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            
            // Email/Phone Toggle
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      title: 'Email',
                      icon: Icons.email_outlined,
                      isSelected: _isEmailSelected,
                      onTap: () => setState(() => _isEmailSelected = true),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      title: 'Phone',
                      icon: Icons.phone_outlined,
                      isSelected: !_isEmailSelected,
                      onTap: () => setState(() => _isEmailSelected = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isEmailSelected)
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (!_isEmailSelected) return null;
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              )
            else
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400]),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (_isEmailSelected) return null;
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernamePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your username',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how other gamers will see you',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Username',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Gaming Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your gaming platforms and favorite genres',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Gaming Platforms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _platforms.map((platform) => _buildChip(
              platform,
              _selectedPlatforms.contains(platform),
              () {
                setState(() {
                  if (_selectedPlatforms.contains(platform)) {
                    _selectedPlatforms.remove(platform);
                  } else {
                    _selectedPlatforms.add(platform);
                  }
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Favorite Genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) => _buildChip(
              genre,
              _selectedGenres.contains(genre),
              () {
                setState(() {
                  if (_selectedGenres.contains(genre)) {
                    _selectedGenres.remove(genre);
                  } else {
                    _selectedGenres.add(genre);
                  }
                });
              },
            )).toList(),
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
      selectedColor: AppTheme.accentColor,
      checkmarkColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
} 