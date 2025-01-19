import 'package:flutter/material.dart';
import 'package:ludicapp/features/authentication/presentation/login_page.dart';
import 'package:ludicapp/features/authentication/presentation/login_verification_page.dart';
import 'package:ludicapp/features/authentication/presentation/register_page.dart';
import 'package:ludicapp/features/authentication/presentation/verification_page.dart';
import 'package:ludicapp/features/onboarding/presentation/onboarding_page.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';
import 'package:ludicapp/main_layout.dart';
import 'package:ludicapp/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Mock login kontrolü - şimdilik her zaman true dönüyor
  Future<bool> _checkIfLoggedIn() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Gerçekçi olması için kısa bir delay
    return true; // Her zaman login olmuş gibi davran
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LudicApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(
            overscroll: false,
            physics: const ClampingScrollPhysics(),
          ),
          child: child ?? const SizedBox(),
        );
      },
      home: FutureBuilder<bool>(
        future: _checkIfLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: AppTheme.primaryDark,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          return const SplashScreen(); // Her zaman splash screen'e git
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainLayout(),
        '/onboarding': (context) => const OnboardingPage(),
        '/login_verification': (context) => const LoginVerificationPage(),
        '/splash': (context) => const SplashScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verification') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VerificationPage(
              email: args['email'] as String,
              verificationCode: args['verificationCode'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}
