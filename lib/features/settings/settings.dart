// lib/features/settings/settings.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/settings/screens/about_screen.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/screens/login_screen.dart';
import 'package:sway/features/user/profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    // Listen to authentication state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _checkAuthStatus();
    });
  }

  /// Checks if the user is currently authenticated.
  Future<void> _checkAuthStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  /// Navigates to the Profile screen if authenticated, else prompts login.
  void _navigateToProfile() {
    if (_isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      _showLoginPrompt();
    }
  }

  /// Navigates to the About screen.
  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  /// Shows a dialog prompting the user to log in.
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You need to log in to access this feature.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  /// Handles the sign-out process.
  Future<void> _handleSignOut() async {
    await _userService.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully signed out')),
    );
  }

  /// Builds the UI for the settings screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Option
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: _navigateToProfile,
          ),
          // Settings Option (additional settings can be added here)
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to additional settings if implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings to be implemented')),
              );
            },
          ),
          // About Option
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: _navigateToAbout,
          ),
          const Divider(),
          // Login/Logout Option
          ListTile(
            leading: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            title: Text(_isLoggedIn ? 'Logout' : 'Login'),
            onTap: _isLoggedIn
                ? _handleSignOut
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
