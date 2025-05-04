import 'package:flutter/cupertino.dart';
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
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    // final bool isDark = theme.brightness == Brightness.dark; // No longer needed for background

    // Set background color directly from theme's scaffold background color
    final Color backgroundColor = theme.scaffoldBackgroundColor;

    // Use the theme's primary color for active items
    final Color activeColor = theme.primaryColor;
    // Use secondary label color for inactive items
    final Color inactiveColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      // Use the theme's scaffold background color directly
      backgroundColor: backgroundColor,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      iconSize: 26.0,
      border: null, // No border
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.home),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Home', // Change label to English
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.compass),
          activeIcon: Icon(CupertinoIcons.compass_fill),
          label: 'Explore', // Change label to English
        ),
        // Remove the "Haberler" item
        // BottomNavigationBarItem(
        //   icon: Icon(CupertinoIcons.bolt_fill),
        //   activeIcon: Icon(CupertinoIcons.bolt_fill),
        //   label: 'Haberler',
        // ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person),
          activeIcon: Icon(CupertinoIcons.person_fill),
          label: 'Profile', // Change label to English
        ),
      ],
    );
  }
}

