import 'package:flutter/material.dart';
import 'package:ludicapp/services/repository/user_repository.dart';
import 'package:ludicapp/models/user_status.dart';

class AuthMiddleware extends NavigatorObserver {
  final UserRepository _userRepository = UserRepository();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    super.didPush(route, previousRoute);
    await _checkUserStatus(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) async {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      await _checkUserStatus(newRoute);
    }
  }

  Future<void> _checkUserStatus(Route<dynamic> route) async {
    // Eğer route splash, landing, login, register veya onboarding ise kontrol etme
    if (route.settings.name == '/splash' ||
        route.settings.name == '/landing' ||
        route.settings.name == '/login' ||
        route.settings.name == '/register' ||
        route.settings.name == '/onboarding' ||
        route.settings.name == '/banned') {
      return;
    }

    try {
      final profileData = await _userRepository.fetchUserProfile();
      if (profileData == null) return;

      switch (profileData.userStatus) {
        case UserStatus.ONBOARDING:
          navigator?.pushNamedAndRemoveUntil('/onboarding', (route) => false);
          break;
        case UserStatus.BANNED:
          navigator?.pushNamedAndRemoveUntil('/banned', (route) => false);
          break;
        case UserStatus.DELETED:
          navigator?.pushNamedAndRemoveUntil('/landing', (route) => false);
          break;
        case UserStatus.ACTIVE:
          // Active kullanıcılar için bir şey yapma
          break;
      }
    } catch (e) {
      print('Error checking user status: $e');
    }
  }
} 