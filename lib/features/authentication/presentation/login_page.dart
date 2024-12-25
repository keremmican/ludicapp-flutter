import 'package:flutter/material.dart';
import 'package:ludicapp/core/widgets/animated_background.dart';
import 'package:ludicapp/features/authentication/presentation/register_page.dart';
import 'package:ludicapp/main_layout.dart';
import 'google_login_button.dart';
import 'steam_login_button.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic background with darker gradients
          Positioned.fill(
            child: AnimatedBackground(),
          ),

          // Logo in the center of the screen
          Align(
            alignment: Alignment(0, -0.6), // Center the logo vertically above the inputs
            child: SizedBox(
              height: 250,
              child: Image.asset(
                'lib/assets/images/app_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Full black background at the bottom with rounded upper corners
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              decoration: BoxDecoration(
                color: Colors.black, // Pure black background
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Google and Steam logos in the center row with separator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Button with reduced padding
                      Padding(
                        padding: EdgeInsets.zero, // Reduced padding
                        child: GoogleLoginButton(),
                      ),
                      const SizedBox(width: 15), // Padding before separator
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.white.withOpacity(0.5), // Separator line
                      ),
                      const SizedBox(width: 15), // Padding after separator
                      // Steam Button with reduced padding
                      Padding(
                        padding: EdgeInsets.zero, // Reduced padding
                        child: SteamLoginButton(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider line
                  Divider(
                    color: Colors.white.withOpacity(0.5), // Slight white line
                    thickness: 1,
                  ),
                  const SizedBox(height: 10),

                  // Email input and sign-in button in the same row
                  Row(
                    children: [
                      // Email input
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A), // Dark gray
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0), // Slight roundness
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Sign in button with icon
                      ElevatedButton(
                        onPressed: () {
                                  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => MainLayout()),
  );
},

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBFE429), // Neon green (#bfe429)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // Slight roundness
                          ),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Register now link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register Now',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
