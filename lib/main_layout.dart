import 'package:flutter/material.dart';
import 'features/home/presentation/home_page.dart';
import 'features/recommendations/presentation/recommendations_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'core/widgets/top_nav_bar.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'package:ludicapp/services/token_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final _tokenService = TokenService();

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> signOut() async {
    await _tokenService.clearAuthData();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/landing',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const RecommendationPage(),
      const ProfilePage(isBottomNavigation: true),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const TopNavBar(),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
