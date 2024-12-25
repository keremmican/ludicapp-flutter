import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool isChecked = false;
  String? selectedDate;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Full black background
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(label: 'Full Name', validator: _validateRequired),
              const SizedBox(height: 20),

              _buildInputField(label: 'Username', validator: _validateRequired),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                validator: _validateRequired,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) => _validatePasswordMatch(value, _passwordController.text),
              ),
              const SizedBox(height: 20),

              // Birth Date Input with DatePicker
              GestureDetector(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFBFE429), // Neon green for date picker
                            onPrimary: Colors.black,
                            surface: Colors.black,
                            onSurface: Colors.white,
                          ),
                          dialogBackgroundColor: Colors.black,
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    final age = DateTime.now().year - pickedDate.year;
                    if (age >= 15) {
                      setState(() {
                        selectedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You must be at least 15 years old')),
                      );
                    }
                  }
                },
                child: _buildInputField(
                  label: selectedDate ?? 'Birth Date (DD/MM/YYYY)',
                  enabled: false, // Disable manual input
                  validator: _validateRequired,
                ),
              ),
              const SizedBox(height: 20),

              // Checkbox for User Agreement
              Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = value!;
                      });
                    },
                    activeColor: const Color(0xFFBFE429), // Neon green
                  ),
                  const Expanded(
                    child: Text(
                      'I acknowledge the user agreement',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Register Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && isChecked) {
                    print('Registered Successfully');
                  } else if (!isChecked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please acknowledge the user agreement')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBFE429), // Neon green
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Slight roundness
                  ),
                ),
                child: const Text(
                  'Register Now',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    bool obscureText = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF2A2A2A).withOpacity(0.9), // Dark background with opacity
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0), // Slight roundness
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(
          color: Colors.white54, // Same placeholder color as the "Sign In" input
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  // Validators
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePasswordMatch(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
