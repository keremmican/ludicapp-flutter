import 'package:flutter/material.dart';

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print('Google Login');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Slight roundness
        ),
        padding: EdgeInsets.zero, // Removed additional padding
        fixedSize: const Size(60, 60), // Uniform size
      ),
      child: Image.asset(
        'lib/assets/images/google_logo.png',
        height: 30,
        width: 30,
      ),
    );
  }
}
