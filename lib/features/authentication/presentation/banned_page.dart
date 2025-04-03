import 'package:flutter/material.dart';
import 'package:ludicapp/theme/app_theme.dart';

class BannedPage extends StatelessWidget {
  const BannedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block_outlined,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Suspended',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account has been suspended due to a violation of our terms of service. If you believe this is a mistake, please contact our support team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LeagueSpartan',
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implement support contact logic
                    print("Contact Support Pressed");
                  },
                  child: const Text('Contact Support'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 