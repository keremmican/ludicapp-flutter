import 'package:flutter/material.dart';
import 'package:ludicapp/features/authentication/presentation/landing_page.dart';
import 'package:ludicapp/features/authentication/presentation/login_page.dart';
import 'package:ludicapp/features/authentication/presentation/register_page.dart';
import 'package:ludicapp/main_layout.dart';
import 'package:ludicapp/features/onboarding/presentation/onboarding_page.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'package:ludicapp/features/authentication/presentation/banned_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/landing': (context) => const LandingPage(),
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
  '/main': (context) => const MainLayout(),
  '/onboarding': (context) => const OnboardingPage(),
  '/splash': (context) => const SplashScreen(),
  '/banned': (context) => const BannedPage(),
}; 