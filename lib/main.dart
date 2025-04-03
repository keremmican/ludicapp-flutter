import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:ludicapp/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable debug logging
  developer.log('Starting app...', name: 'LudicApp');
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode currentThemeMode = ref.watch(themeProvider);

    // Sistemin varsayılan metin ölçekleme faktörünü al
    final systemTextScaleFactor = MediaQuery.textScaleFactorOf(context);
    // Metin ölçekleme faktörünü sınırla (0.9 ile 1.2 arası)
    final clampedTextScaleFactor = systemTextScaleFactor.clamp(0.9, 1.2);

    return MaterialApp(
      title: 'LudicApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      navigatorKey: ApiService.navigatorKey,
      builder: (context, child) {
        // Önce MediaQuery ile sarmala, sonra ScrollConfiguration
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(clampedTextScaleFactor),
          ),
          child: ScrollConfiguration(
            behavior: ScrollBehavior().copyWith(
              overscroll: false,
              physics: const ClampingScrollPhysics(),
            ),
            child: child ?? const SizedBox(),
          ),
        );
      },
      initialRoute: '/splash',
      routes: routes,
      navigatorObservers: [AuthMiddleware()],
    );
  }
}
