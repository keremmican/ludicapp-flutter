import 'package:flutter/material.dart';
import 'features/home/presentation/home_page.dart';
import 'features/recommendations/presentation/recommendations_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'core/widgets/top_nav_bar.dart';
import 'core/widgets/bottom_nav_bar.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    RecommendationPage(), // Renamed from SwipePage
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: TopNavBar(), // Fixed Top Navigation Bar
      body: _pages[_currentIndex], // Current Page
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ), // Fixed Bottom Navigation Bar
    );
  }
}
