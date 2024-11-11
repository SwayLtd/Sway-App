// lib/features/user/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  // Variables for login attempt limitation
  int _failedAttempts = 0;
  bool _isLocked = false;
  Timer? _lockTimer;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 2);

  /// Validates the email input to prevent SQL injections and other issues.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email.';
    }
    return null;
  }

  /// Validates the password input.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    return null;
  }

  /// Handles the sign-in process.
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLocked) {
      setState(() {
        _errorMessage = 'Account locked. Please try again later.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Reset failed attempts after a successful login
      setState(() {
        _failedAttempts = 0;
      });

      // Supabase Auth handles redirection automatically via GoRouter
    } catch (e) {
      setState(() {
        _failedAttempts += 1;
        if (_failedAttempts >= _maxFailedAttempts) {
          _isLocked = true;
          _errorMessage =
              'Account locked due to too many failed attempts. Please try again in ${_lockDuration.inMinutes} minutes.';
          _lockTimer = Timer(_lockDuration, () {
            setState(() {
              _isLocked = false;
              _failedAttempts = 0;
              _errorMessage = null;
            });
          });
        } else {
          _errorMessage =
              'Login failed. Please check your credentials. Attempt $_failedAttempts of $_maxFailedAttempts.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Disposes controllers and timers to free resources.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  /// Builds the UI for the login screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Use a Form widget for validation
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email Input Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16.0),
              // Password Input Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 24.0),
              // Display Error Message if Any
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16.0),
              // Login Button
              ElevatedButton(
                onPressed: _isLoading || _isLocked ? null : _handleSignIn,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
