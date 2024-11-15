// lib/features/user/screens/sign_up_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/screens/login_screen.dart';
import 'package:sway/features/user/screens/terms_and_conditions_screen.dart';
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  bool _isPasswordVisible = false;
  bool _isTermsAccepted = false;

  // Validation flags
  bool _isUsernameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  // Default profile picture URL from Supabase Storage
  final String _defaultProfilePictureUrl =
      'https://your-supabase-url.storage.googleapis.com/user-profile-picture/default.png';

  /// Validates the username input.
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      _isUsernameValid = false;
      return 'Please enter your name.';
    }
    _isUsernameValid = true;
    return null;
  }

  /// Validates the email input.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      _isEmailValid = false;
      return 'Please enter your email.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      _isEmailValid = false;
      return 'Please enter a valid email.';
    }
    _isEmailValid = true;
    return null;
  }

  /// Validates the password input.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      _isPasswordValid = false;
      return 'Please enter your password.';
    }
    if (value.length < 8) {
      _isPasswordValid = false;
      return 'Password must be at least 8 characters long.';
    }
    _isPasswordValid = true;
    return null;
  }

  /// Handles the sign-up process.
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid inputs
      return;
    }

    if (!_isTermsAccepted) {
      setState(() {
        _errorMessage = 'You must accept the Terms and Conditions.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Sign up with AuthService, including username in raw_user_meta_data
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );

      // No need to manually create a user entry; the trigger handles it.

      // Optionally, you can automatically sign in the user or navigate them to another screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Sign-up successful! Please check your email to verify your account.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on AuthenticationException catch (e) {
      setState(() {
        _errorMessage = _getAuthErrorMessage(e.message);
      });
    } catch (e) {
      print('Sign-up Error: $e'); // Debugging
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Maps Supabase Auth error messages to user-friendly messages.
  String _getAuthErrorMessage(String message) {
    switch (message.toLowerCase()) {
      case 'email already registered':
        return 'This email is already in use. Please try logging in or use a different email.';
      case 'invalid email':
        return 'The email address is not valid.';
      case 'password should be at least 8 characters':
      case 'password must be at least 8 characters long.':
        return 'Password must be at least 8 characters long.';
      default:
        return 'Sign-up failed: $message';
    }
  }

  /// Builds the UI for the sign-up screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        // Prevent overflow on smaller screens
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Use a Form widget for validation
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Username Input Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your first and last name',
                    suffixIcon: _isUsernameValid
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                  ),
                  validator: _validateUsername,
                  onChanged: (value) {
                    _formKey.currentState!.validate();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16.0),
                // Email Input Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    suffixIcon: _isEmailValid
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  onChanged: (value) {
                    _formKey.currentState!.validate();
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
                        if (_isPasswordValid)
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
                    _formKey.currentState!.validate();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 24.0),
                // Terms and Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (bool? value) {
                        setState(() {
                          _isTermsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to Terms and Conditions Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const TermsAndConditionsScreen()),
                          );
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            children: [
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                // Display Error Message if Any
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 16.0),
                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
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
                      : const Text('Sign Up'),
                ),
                const SizedBox(height: 24.0),
                const Divider(),
                const SizedBox(height: 16.0),
                // OAuth Sign-Up Buttons (Disabled for now)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Or sign up with:',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
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
                                content: Text(
                                    'Google sign-up will be available soon.'),
                              ),
                            );
                          },
                          tooltip: 'Sign Up with Google',
                        ),
                        // Apple
                        IconButton(
                          icon: const Icon(Icons.apple),
                          color: Colors.grey,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Apple sign-up will be available soon.'),
                              ),
                            );
                          },
                          tooltip: 'Sign Up with Apple',
                        ),
                        // Facebook
                        IconButton(
                          icon: const Icon(Icons.facebook),
                          color: Colors.grey,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Facebook sign-up will be available soon.'),
                              ),
                            );
                          },
                          tooltip: 'Sign Up with Facebook',
                        ),
                        // Spotify
                        IconButton(
                          icon: const Icon(Icons.music_note),
                          color: Colors.grey,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Spotify sign-up will be available soon.'),
                              ),
                            );
                          },
                          tooltip: 'Sign Up with Spotify',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                // Navigate to Login Screen
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text('Login here.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
