import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/core/utils/validators.dart';
import 'package:ludicapp/services/repository/auth_repository.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  final bool isLoginFlow;
  const LoginPage({super.key, this.isLoginFlow = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEmailSelected = true;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isUserValid = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 180; // 3 dakika
  bool _isFirstAttempt = true;
  bool _isCodeError = false;

  final _authRepository = AuthRepository();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return phone.length >= 10;
  }

  @override
  void initState() {
    super.initState();
    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _emailController.addListener(() => _onInputChanged(_emailController.text));
    _phoneController.addListener(() => _onInputChanged(_phoneController.text));
    _verificationController.addListener(_onVerificationCodeChanged);
  }

  void _onInputChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    setState(() {
      _isUserValid = false;
      _errorMessage = '';
    });

    if (value.isEmpty) return;

    final bool isValidFormat = _isEmailSelected 
        ? _isValidEmail(value)
        : _isValidPhone(value);

    if (!isValidFormat) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUserExists(value);
    });
  }

  Future<void> _checkUserExists(String value) async {
    print('Checking User Exists: {value: $value, isLoginFlow: ${widget.isLoginFlow}}');

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    final result = await _authRepository.checkUserExists(
      emailOrPhone: value,
      isLoginFlow: widget.isLoginFlow,
    );
    
    print('User Check Result: $result');

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isUserValid = result['success'] ?? false;
        _errorMessage = result['message'] ?? '';
      });
    }
  }

  void _startCountdown() {
    _remainingSeconds = 180;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onVerificationCodeChanged() {
    final code = _verificationController.text;
    if (code.length == 6 && _isFirstAttempt) {
      _isFirstAttempt = false;
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isCodeError = false;
    });
    
    final String emailOrPhone = _isEmailSelected ? _emailController.text : _phoneController.text;
    final result = await _authRepository.verifyOtp(
      emailOrPhone: emailOrPhone,
      code: _verificationController.text,
      isLoginFlow: true,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isCodeError = !(result['success'] ?? false);
      });

      if (result['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/splash',
          (route) => false,
        );
      } else {
        // Vibrate when code is wrong
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleContinue() async {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        final String emailOrPhone = _isEmailSelected ? _emailController.text : _phoneController.text;
        
        setState(() => _isLoading = true);
        final success = await _authRepository.sendOtp(emailOrPhone: emailOrPhone);
        setState(() => _isLoading = false);

        if (success && mounted) {
          setState(() => _currentStep = 1);
          _startCountdown();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP gönderilirken bir hata oluştu')),
          );
        }
      }
    } else {
      _verifyCode();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _countdownTimer?.cancel();
    _emailController.dispose();
    _phoneController.dispose();
    _verificationController.dispose();
    super.dispose();
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
                                    onTap: () {},
                                    isDisabled: true,
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
                                suffixIcon: _buildSuffixIcon(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (!_isEmailSelected) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!_isValidEmail(value)) {
                                  return 'Please enter a valid email';
                                }
                                return _errorMessage.isNotEmpty ? _errorMessage : null;
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
                                suffixIcon: _buildSuffixIcon(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (_isEmailSelected) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (!_isValidPhone(value)) {
                                  return 'Please enter a valid phone number';
                                }
                                return _errorMessage.isNotEmpty ? _errorMessage : null;
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
                            style: TextStyle(
                              color: _isCodeError ? Colors.red : Colors.white,
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
                                borderSide: BorderSide(
                                  color: _isCodeError ? Colors.red : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _isCodeError ? Colors.red : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _isCodeError ? Colors.red : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Time Remaining: $_formattedTime',
                                style: TextStyle(
                                  color: _remainingSeconds > 0 ? Colors.white : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: _remainingSeconds == 0 && !_isLoading ? _resendCode : null,
                                child: Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    color: _remainingSeconds == 0 && !_isLoading 
                                        ? AppTheme.accentColor 
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                  onPressed: _currentStep == 0 && !_isUserValid || _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUserValid ? AppTheme.accentColor : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 0 ? 'Continue' : 'Verify',
                              style: TextStyle(
                                color: _isUserValid ? Colors.black : Colors.grey[400],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentStep == 0 && !_isUserValid) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.lock_outline,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ],
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
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Stack(
        children: [
          Container(
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
          if (isDisabled)
            Positioned(
              right: 8,
              top: 8,
              child: Icon(
                Icons.lock_outline,
                color: Colors.grey[400],
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (_isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
        ),
      );
    }
    
    final String value = _isEmailSelected ? _emailController.text : _phoneController.text;
    if (value.isEmpty) return const SizedBox.shrink();

    return Icon(
      _isUserValid ? Icons.check_circle : Icons.error,
      color: _isUserValid ? Colors.green : Colors.red,
      size: 24,
    );
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    final emailOrPhone = _isEmailSelected ? _emailController.text : _phoneController.text;
    final success = await _authRepository.sendOtp(emailOrPhone: emailOrPhone);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP gönderilirken bir hata oluştu')),
        );
      }
    }
  }
}

