// lib/features/user/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/screens/sign_up_screen.dart';
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  // Variables for login attempt limitation
  int _failedAttempts = 0;
  bool _isLocked = false;
  Timer? _lockTimer;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 2);

  bool _isPasswordVisible = false;

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
      // Step 1: Sign in with AuthService
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Optionally, fetch user details
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User details not found.');
      }

      // Reset failed attempts after a successful login
      setState(() {
        _failedAttempts = 0;
      });

      // Navigate to the main application screen or wherever appropriate
      // For example:
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } on AuthenticationException catch (e) {
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
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
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
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  suffixIcon:
                      _validateEmail(_emailController.text.trim()) == null
                          ? null
                          : const Icon(Icons.check, color: Colors.green),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16.0),
              // Password Input Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Check Icon
                      if (_validatePassword(_passwordController.text.trim()) ==
                          null)
                        const Icon(Icons.check, color: Colors.green),
                      // Toggle Password Visibility
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: _validatePassword,
                onChanged: (value) {
                  setState(() {});
                },
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
              const Spacer(),
              // OAuth Login Buttons (Disabled for now)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Or login with:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      IconButton(
                        icon: const Icon(Icons.g_mobiledata),
                        color: Colors.grey,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Google login will be available soon.'),
                            ),
                          );
                        },
                        tooltip: 'Login with Google',
                      ),
                      // Apple
                      IconButton(
                        icon: const Icon(Icons.apple),
                        color: Colors.grey,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Apple login will be available soon.'),
                            ),
                          );
                        },
                        tooltip: 'Login with Apple',
                      ),
                      // Facebook
                      IconButton(
                        icon: const Icon(Icons.facebook),
                        color: Colors.grey,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Facebook login will be available soon.'),
                            ),
                          );
                        },
                        tooltip: 'Login with Facebook',
                      ),
                      // Spotify
                      IconButton(
                        icon: const Icon(Icons.music_note),
                        color: Colors.grey,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Spotify login will be available soon.'),
                            ),
                          );
                        },
                        tooltip: 'Login with Spotify',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              // Navigate to Sign-Up Screen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text('Sign up here.'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
