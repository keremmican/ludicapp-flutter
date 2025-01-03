import 'package:flutter/material.dart';
import 'package:ludicapp/features/search/presentation/search_page.dart';
import 'package:ludicapp/features/notifications/presentation/notifications_page.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Notifications Icon
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),

          // App Logo
          SizedBox(
            height: 60, // Increased logo size
            child: Image.asset(
              'lib/assets/images/app_logo_2.png',
              fit: BoxFit.contain,
            ),
          ),

          // Search Icon
          IconButton(
            icon: const Icon(Icons.search),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
