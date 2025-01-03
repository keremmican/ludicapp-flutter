import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:ludicapp/theme/app_theme.dart';
import 'package:ludicapp/core/utils/validators.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the gaming community',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField('Username', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField('Email', Icons.email_outlined, 
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!Validators.isValidEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField('Password', Icons.lock_outline, isPassword: true),
                const SizedBox(height: 16),
                _buildDatePicker(context),
                const SizedBox(height: 24),

                // Terms of Service Checkbox
                _buildTermsCheckbox(),
                const SizedBox(height: 24),

                if (!_isAdult)
                  const Text(
                    'You must be 18 or older to register',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),

                const SizedBox(height: 16),

                if (!_acceptedTerms)
                  const Text(
                    'Please accept the Terms of Service to continue',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isAdult && _acceptedTerms) ? _handleRegister : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: (_isAdult && _acceptedTerms) ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {
    bool isPassword = false, 
    TextEditingController? controller, 
    String? Function(String?)? validator
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: isPassword,
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (hint == 'Email' && !Validators.isValidEmail(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: Colors.grey[400]),
        title: Text(
          _selectedDate == null
              ? 'Date of Birth'
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          style: TextStyle(
            color: _selectedDate == null ? Colors.grey[400] : Colors.white,
          ),
        ),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentColor,
              surface: AppTheme.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Yaş kontrolü için bugünün tarihini alıyoruz
      final today = DateTime.now();
      
      // Doğum tarihinden bugüne kaç yıl geçtiğini hesaplıyoruz
      int age = today.year - picked.year;
      
      // Eğer bu yıl henüz doğum günü gelmediyse yaşı bir azaltıyoruz
      if (today.month < picked.month || 
          (today.month == picked.month && today.day < picked.day)) {
        age--;
      }

      setState(() {
        _selectedDate = picked;
        _isAdult = age >= 18; // 18 yaşından büyük mü kontrolü
        
        if (!_isAdult) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be 18 or older to register'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate() && _isAdult && _acceptedTerms) {
      // Mock verification code
      const verificationCode = '123456';
      
      // Navigate to verification page with arguments
      Navigator.pushNamed(
        context,
        '/verification',
        arguments: {
          'email': _emailController.text,
          'verificationCode': verificationCode,
        },
      );
    }
  }

  Widget _buildTermsCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
              });
            },
            fillColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? AppTheme.accentColor
                  : Colors.grey[400],
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                children: [
                  const TextSpan(text: 'I accept the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Terms of Service sayfasına yönlendirme
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Privacy Policy sayfasına yönlendirme
                      },
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
