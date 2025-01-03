import 'package:flutter/material.dart';

class SteamLoginButton extends StatelessWidget {
  const SteamLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print('Steam Login');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B2838),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Slight roundness
        ),
        padding: EdgeInsets.zero, // Removed additional padding
        fixedSize: const Size(60, 60), // Uniform size
      ),
      child: Image.asset(
        'lib/assets/images/steam_logo.png',
        height: 30,
        width: 30,
      ),
    );
  }
}
