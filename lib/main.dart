import 'package:flutter/material.dart';
import 'package:ludicapp/features/authentication/presentation/landing_page.dart';
import 'package:ludicapp/features/authentication/presentation/login_page.dart';
import 'package:ludicapp/features/authentication/presentation/register_page.dart';
import 'package:ludicapp/features/onboarding/presentation/onboarding_page.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'package:ludicapp/features/authentication/presentation/banned_page.dart';
import 'package:ludicapp/main_layout.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/services/api_service.dart';
import 'package:ludicapp/services/token_service.dart';
import 'package:ludicapp/routes.dart';
import 'package:ludicapp/core/middleware/auth_middleware.dart';
import 'dart:developer' as developer;

void main() {
  // Enable debug logging
  developer.log('Starting app...', name: 'LudicApp');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkIfLoggedIn() async {
    final tokenService = TokenService();
    final token = await tokenService.getAccessToken();
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LudicApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: ApiService.navigatorKey,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(
            overscroll: false,
            physics: const ClampingScrollPhysics(),
          ),
          child: child ?? const SizedBox(),
        );
      },
      initialRoute: '/splash',
      routes: routes,
      navigatorObservers: [AuthMiddleware()],
    );
  }
}
