import 'package:flutter/material.dart';
import 'package:ludicapp/features/search/presentation/search_page.dart';
import 'package:ludicapp/features/notifications/presentation/notifications_page.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema renklerini al
    final theme = Theme.of(context);
    // İkon rengi: Koyu temada beyaz, açık temada koyu gri
    final iconColor = theme.brightness == Brightness.dark 
        ? Colors.white 
        : Colors.grey[800];
        
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Notifications Icon
          IconButton(
            icon: const Icon(Icons.notifications),
            color: iconColor, // Tema uyumlu renk
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
            height: 40, // Increased logo size
            child: Image.asset(
              'lib/assets/images/app_logo.png',
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),

          // Search Icon
          IconButton(
            icon: const Icon(Icons.search),
            color: iconColor, // Tema uyumlu renk
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
