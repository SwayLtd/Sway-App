// lib/features/settings/settings.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/features/notification/screens/notification_preferences_screen.dart';
import 'package:sway/features/settings/screens/about_screen.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/auth_modal.dart';
import 'package:sway/features/user/profile.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  AppUser.User? _currentUser;

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
    final fetchedUser = await _userService.getCurrentUser();
    setState(() {
      _isLoggedIn = fetchedUser != null;
      _currentUser = fetchedUser;
    });
  }

  /// Navigates to the Profile screen if authenticated, else opens AuthModal.
  void _navigateToProfile() {
    if (_isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      _showAuthModal();
    }
  }

  /// Navigates to the About screen.
  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  /// Opens the AuthModal as a bottom sheet.
  void _showAuthModal() {
    AuthModal.showAuthModal(context);
  }

  /// Handles the sign-out process.
  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Successfully signed out'),
        ),
      );
      // Optionally navigate to the login screen or another screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error signing out: $e'),
        ),
      );
    }
  }

  /// Change the theme mode
  void _changeTheme(AdaptiveThemeMode mode) async {
    AdaptiveTheme.of(context).setThemeMode(mode);
  }

  /// Affiche un dialogue pour sélectionner le thème
  void _showThemeSelectionDialog() {
    AdaptiveThemeMode currentMode = AdaptiveTheme.of(context).mode;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AdaptiveThemeMode>(
                title: const Text('System Default'),
                value: AdaptiveThemeMode.system,
                groupValue: currentMode,
                onChanged: (AdaptiveThemeMode? value) {
                  if (value != null) {
                    _changeTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<AdaptiveThemeMode>(
                title: const Text('Light'),
                value: AdaptiveThemeMode.light,
                groupValue: currentMode,
                onChanged: (AdaptiveThemeMode? value) {
                  if (value != null) {
                    _changeTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<AdaptiveThemeMode>(
                title: const Text('Dark'),
                value: AdaptiveThemeMode.dark,
                groupValue: currentMode,
                onChanged: (AdaptiveThemeMode? value) {
                  if (value != null) {
                    _changeTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the UI for the settings screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          // Contenu défilable
          Expanded(
            child: ListView(
              children: [
                if (_isLoggedIn && _currentUser != null)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(_currentUser!.profilePictureUrl),
                    ),
                    title: Text(_currentUser!.username),
                    subtitle: Text(_currentUser!.email),
                    onTap: _navigateToProfile,
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign Up or Login'),
                    onTap: _showAuthModal,
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notification Preferences'),
                  onTap: _isLoggedIn
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationPreferencesScreen(),
                            ),
                          );
                        }
                      : _showAuthModal,
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Theme'),
                  subtitle: const Text('Choose light, dark or system theme'),
                  onTap: _showThemeSelectionDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  onTap: _navigateToAbout,
                ),
                const Divider(),
                SizedBox(height: sectionSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Copyright © 2025 - '),
                    Text(
                      'Sway',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sectionSpacing),
              ],
            ),
          ),
          // Bouton "Log out" en bas
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 150,
                child: TextButton(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  onPressed: _handleSignOut,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
