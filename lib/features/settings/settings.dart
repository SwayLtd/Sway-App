// lib/features/settings/settings.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/features/artist/screens/create_artist_screen.dart';
import 'package:sway/features/notification/screens/notification_preferences_screen.dart';
import 'package:sway/features/promoter/screens/create_promoter_screen.dart';
import 'package:sway/features/settings/screens/about_screen.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/auth_modal.dart';
import 'package:sway/features/user/profile.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:sway/features/venue/screens/create_venue_screen.dart'; // Importez le nouvel écran de création

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

  /// Vérifie si l'utilisateur est connecté et son statut de confirmation d'email.
  Future<void> _checkAuthStatus() async {
    final fetchedUser = await _userService.getCurrentUser();

    if (fetchedUser != null) {}

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

  /// Affiche le menu de création d'entités
  void _showCreateEntityMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              // Barre grise horizontale
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Create Venue'),
                onTap: () {
                  Navigator.pop(context); // Fermer le menu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateVenueScreen()),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.whatshot), // Icons.confirmation_number
                title: const Text('Create Promoter'),
                onTap: () {
                  Navigator.pop(context); // Fermer le menu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreatePromoterScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.headset_mic),
                title: const Text('Create Artist'),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateArtistScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event, color: Colors.grey),
                title: const Text('Create Event'),
                enabled: false, // Désactivé
                onTap: null, // Inactif
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
      // Ajout du FloatingActionButton
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: _showCreateEntityMenu,
              child: const Icon(Icons.add),
              tooltip: 'Create Entity',
            )
          : null,
    );
  }
}
