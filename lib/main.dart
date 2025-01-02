import 'package:flutter/material.dart';
import 'package:ludicapp/features/game/presentation/game_detail_page.dart';
import 'main_layout.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Discovery',
      theme: ThemeData(
        fontFamily: 'League Spartan',
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFBFE429),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainLayout(),
        '/game-detail': (context) {
          final gameId = ModalRoute.of(context)?.settings.arguments as int?;
          if (gameId == null) {
            return MainLayout();
          }
          return GameDetailPage(id: gameId);
        },
      },
    );
  }
}
