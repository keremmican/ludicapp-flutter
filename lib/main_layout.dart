import 'package:flutter/material.dart';
import 'features/home/presentation/home_page.dart';
import 'features/recommendations/presentation/recommendations_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'core/widgets/top_nav_bar.dart';
import 'core/widgets/bottom_nav_bar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const RecommendationPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const TopNavBar(),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
