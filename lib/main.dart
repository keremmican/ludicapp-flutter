import 'package:flutter/material.dart';
import 'package:ludicapp/features/authentication/presentation/login_page.dart';
import 'package:ludicapp/features/authentication/presentation/register_page.dart';
import 'package:ludicapp/features/authentication/presentation/verification_page.dart';
import 'package:ludicapp/main_layout.dart';
import 'package:ludicapp/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LudicApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainLayout(),
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
