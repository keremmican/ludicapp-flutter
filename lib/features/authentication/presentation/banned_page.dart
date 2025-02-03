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
                  onPressed: () {
                    // TODO: Add support email or contact form link
                    // For now, just show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support contact feature coming soon'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 