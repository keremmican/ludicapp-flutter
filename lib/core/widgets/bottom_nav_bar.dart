import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tema renklerini al
    final theme = Theme.of(context);
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Accent rengi temadan al
      selectedItemColor: theme.colorScheme.primary, // Tema accent rengi
      // Temaya göre seçilmemiş item rengi (açık/koyu temada farklı)
      unselectedItemColor: theme.brightness == Brightness.dark 
          ? Colors.white54 // Koyu temada açık gri
          : Colors.grey[700], // Açık temada koyu gri
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.swipe),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }
}
