// lib/features/user/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/screens/login_screen.dart';
import 'package:sway/features/user/widgets/captcha_widget.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String? _captchaToken;

  // Replace with your hCaptcha secret key
  final String _hCaptchaSecret = 'YOUR_HCAPTCHA_SECRET_KEY';

  void _onCaptchaVerified(String token) {
    setState(() {
      _captchaToken = token;
    });
  }

  /// Verifies the hCaptcha token with hCaptcha's siteverify API.
  Future<bool> _verifyCaptcha(String token) async {
    final response = await http.post(
      Uri.parse('https://hcaptcha.com/siteverify'),
      body: {
        'secret': _hCaptchaSecret,
        'response': token,
      },
    );

    if (response.statusCode != 200) {
      return false;
    }

    final jsonResponse = json.decode(response.body);
    return jsonResponse['success'] as bool;
  }

  Future<void> _handleMagicLinkSignUp() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email.';
      });
      return;
    }

    if (_captchaToken == null) {
      setState(() {
        _errorMessage = 'Please complete the CAPTCHA challenge.';
      });
      return;
    }

    // Verify CAPTCHA token with hCaptcha
    final captchaValid = await _verifyCaptcha(_captchaToken!);
    if (!captchaValid) {
      setState(() {
        _errorMessage = 'CAPTCHA verification failed.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Magic link sent! Check your email to complete sign-up.'),
        ),
      );
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOAuthSignUp(OAuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo:
            'https://your-app-url.com/callback', // Replace with your redirect URL
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          child: Column(
            children: [
              // Email Input Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email for a magic link',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleMagicLinkSignUp,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Sign Up with Magic Link'),
              ),
              const SizedBox(height: 24.0),
              const Text('Or sign up with:'),
              const SizedBox(height: 16.0),
              // OAuth Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google
                  IconButton(
                    icon: const Icon(Icons.login),
                    onPressed: _isLoading
                        ? null
                        : () => _handleOAuthSignUp(OAuthProvider.google),
                    tooltip: 'Sign Up with Google',
                  ),
                  // Apple
                  IconButton(
                    icon: const Icon(Icons.apple),
                    onPressed: _isLoading
                        ? null
                        : () => _handleOAuthSignUp(OAuthProvider.apple),
                    tooltip: 'Sign Up with Apple',
                  ),
                  // Spotify
                  IconButton(
                    icon: const Icon(Icons.music_note),
                    onPressed: _isLoading
                        ? null
                        : () => _handleOAuthSignUp(OAuthProvider.spotify),
                    tooltip: 'Sign Up with Spotify',
                  ),
                  // Facebook
                  IconButton(
                    icon: const Icon(Icons.facebook),
                    onPressed: _isLoading
                        ? null
                        : () => _handleOAuthSignUp(OAuthProvider.facebook),
                    tooltip: 'Sign Up with Facebook',
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              // CAPTCHA Widget
              const Text('Please complete the CAPTCHA below:'),
              SizedBox(
                height: 100, // Adjusted height for better UI
                child: CaptchaWidget(onVerified: _onCaptchaVerified),
              ),
              const SizedBox(height: 16.0),
              // Display Error Message if Any
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16.0),
              // Navigate to Login Screen
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Already have an account? Login here.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
