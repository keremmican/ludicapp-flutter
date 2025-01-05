import 'package:flutter/material.dart';
import 'package:ludicapp/theme/app_theme.dart';

class LoginVerificationPage extends StatefulWidget {
  const LoginVerificationPage({super.key});

  @override
  State<LoginVerificationPage> createState() => _LoginVerificationPageState();
}

class _LoginVerificationPageState extends State<LoginVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEmailSelected = true;
  int _currentStep = 0; // 0: email/phone input, 1: verification code

  // Controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        // Mock sending verification code
        setState(() => _currentStep = 1);
      }
    } else {
      // Verify code and login
      if (_verificationController.text.length == 6) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_currentStep == 0) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _currentStep = 0);
                      }
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentStep == 0) ...[
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose how you want to continue',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Email/Phone Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildToggleButton(
                                    title: 'Email',
                                    icon: Icons.email_outlined,
                                    isSelected: _isEmailSelected,
                                    onTap: () => setState(() => _isEmailSelected = true),
                                  ),
                                ),
                                Expanded(
                                  child: _buildToggleButton(
                                    title: 'Phone',
                                    icon: Icons.phone_outlined,
                                    isSelected: !_isEmailSelected,
                                    onTap: () => setState(() => _isEmailSelected = false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_isEmailSelected)
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: AppTheme.surfaceDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (!_isEmailSelected) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            )
                          else
                            TextFormField(
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: AppTheme.surfaceDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400]),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (_isEmailSelected) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (value.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                        ] else ...[
                          const Text(
                            'Verification',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isEmailSelected 
                              ? 'Enter the code sent to your email'
                              : 'Enter the code sent to your phone',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isEmailSelected 
                              ? _emailController.text
                              : _phoneController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _verificationController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              hintText: '000000',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: AppTheme.surfaceDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // Resend verification code
                              },
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentStep == 0 ? 'Continue' : 'Verify',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 