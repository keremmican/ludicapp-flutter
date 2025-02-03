import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/core/utils/validators.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ludicapp/services/repository/auth_repository.dart';
import 'package:ludicapp/services/token_service.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  DateTime? _selectedDate;
  bool _isAdult = false;
  bool _acceptedTerms = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationController = TextEditingController();
  final _usernameController = TextEditingController();

  final _pageController = PageController();
  int _currentPage = 0;
  bool _isEmailSelected = true;
  bool _isLoading = false;
  bool _isUserValid = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 180;
  bool _isFirstAttempt = true;
  bool _isCodeError = false;
  
  final _authRepository = AuthRepository();
  final _tokenService = TokenService();

  @override
  void initState() {
    super.initState();
    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _emailController.addListener(() => _onInputChanged(_emailController.text));
    _phoneController.addListener(() => _onInputChanged(_phoneController.text));
    _verificationController.addListener(_onVerificationCodeChanged);
    _usernameController.addListener(() => _onUsernameChanged(_usernameController.text));
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

  void _onUsernameChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    setState(() {
      _isUserValid = false;
      _errorMessage = '';
    });

    if (value.isEmpty) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameExists(value);
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return phone.length >= 10;
  }

  Future<void> _checkUserExists(String value) async {
    setState(() => _isLoading = true);
    
    final result = await _authRepository.checkUserExists(
      emailOrPhone: value,
      isLoginFlow: false,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isUserValid = result['success'] ?? false;
        _errorMessage = result['message'] ?? '';
      });
    }
  }

  Future<void> _checkUsernameExists(String username) async {
    setState(() => _isLoading = true);
    
    final result = await _authRepository.checkUsernameExists(username);
    
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
      isLoginFlow: false,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isCodeError = !(result['success'] ?? false);
      });

      if (result['success'] == true) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Vibrate when code is wrong
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _verificationController.dispose();
    _usernameController.dispose();
    _debounceTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage == 0) {
      if (!_formKey.currentState!.validate() || !_isUserValid) return;
      
      setState(() => _isLoading = true);
      final emailOrPhone = _isEmailSelected ? _emailController.text : _phoneController.text;
      final success = await _authRepository.sendOtp(emailOrPhone: emailOrPhone);
      setState(() => _isLoading = false);

      if (success && mounted) {
        _startCountdown();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP gönderilirken bir hata oluştu')),
        );
      }
      return;
    }

    if (_currentPage == 1) {
      _verifyCode();
      return;
    }

    // Username page
    if (!_isUserValid) return;
    
    setState(() => _isLoading = true);
    
    final emailOrPhone = _isEmailSelected ? _emailController.text : _phoneController.text;
    try {
      final result = await _authRepository.register(
        emailOrPhone,
        _usernameController.text,
      );
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/splash',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt işlemi sırasında bir hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                      if (_currentPage == 0) {
                        Navigator.pop(context);
                      } else {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                  const Spacer(),
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppTheme.accentColor,
                      dotColor: Colors.grey[800]!,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildEmailPage(),
                  _buildVerificationPage(),
                  _buildUsernamePage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _currentPage == 0 && !_isUserValid ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPage == 0 && !_isUserValid 
                        ? Colors.grey 
                        : AppTheme.accentColor,
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
                              _currentPage == 2 ? 'Get Started' : 'Continue',
                              style: TextStyle(
                                color: _currentPage == 0 && !_isUserValid 
                                    ? Colors.grey[400]
                                    : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentPage == 0 && !_isUserValid) ...[
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

  Widget _buildEmailPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome!',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        ),
      ),
    );
  }

  Widget _buildUsernamePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your username',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is how other gamers will see you',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Username',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                suffixIcon: _buildSuffixIcon(),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
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
    
    final String value = _currentPage == 2 
        ? _usernameController.text 
        : (_isEmailSelected ? _emailController.text : _phoneController.text);
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
