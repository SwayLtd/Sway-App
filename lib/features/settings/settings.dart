// lib/features/settings/settings.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/screens/create_artist_screen.dart';
import 'package:sway/features/event/screens/create_event_screen.dart';
import 'package:sway/features/notification/screens/notification_preferences_screen.dart';
import 'package:sway/features/promoter/screens/create_promoter_screen.dart';
import 'package:sway/features/settings/screens/about_screen.dart';
import 'package:sway/features/settings/screens/help_screen.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/screens/user_entities_screen.dart';
import 'package:sway/features/user/services/auth_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/user.dart';
import 'package:sway/features/user/widgets/auth_modal.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:sway/features/venue/screens/create_venue_screen.dart';

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
  // Indicates whether the user profile has been loaded
  bool _isUserLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Listen for authentication state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _loadUser();
    });
  }

  Future<void> _loadUser() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoggedIn = user != null;
      _isUserLoaded = true;
    });
  }

  /// Navigates to the profile screen if logged in; otherwise, shows the authentication modal.
  void _navigateToProfile() {
    if (_isLoggedIn && _currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => UserScreen(userId: _currentUser!.id)),
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

  /// Displays the authentication modal.
  void _showAuthModal() {
    AuthModal.showAuthModal(context);
  }

  /// Handles signing out.
  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Successfully signed out'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error signing out: $e'),
        ),
      );
    }
  }

  /// Changes the theme mode.
  void _changeTheme(AdaptiveThemeMode mode) async {
    AdaptiveTheme.of(context).setThemeMode(mode);
  }

  /// Displays a dialog for theme selection.
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

  /// Checks if the user has at least 'manager' permission to create an event.
  Future<bool> _canCreateEvent() async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) return false;
    final perms = await UserPermissionService()
        .getPermissionsByUserIdAndType(currentUser.id, 'promoter');
    return perms.any((p) => p.permissionLevel >= 2);
  }

  /// Displays the entity creation menu.
  void _showCreateEntityMenu() async {
    final bool canCreateEvent = await _canCreateEvent();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              // Grey horizontal bar in the center.
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
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateVenueScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.whatshot),
                title: const Text('Create Promoter'),
                onTap: () {
                  Navigator.pop(context);
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
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateArtistScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.event,
                  color: canCreateEvent ? null : Colors.grey,
                ),
                title: Text(
                  'Create Event',
                  style: TextStyle(
                    color: canCreateEvent ? null : Colors.grey,
                  ),
                ),
                enabled: canCreateEvent,
                onTap: canCreateEvent
                    ? () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CreateEventScreen()),
                        );
                      }
                    : () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You must manage a promoter to create an event.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
        actions: [
          // Help bubble on the rightIconButton(
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content.
          Expanded(
            child: ListView(
              children: [
                // Profile ListTile is always displayed.
                // Profile ListTile
                _isUserLoaded
                    ? (_isLoggedIn && _currentUser != null
                        ? ListTile(
                            leading: ClipOval(
                              child: ImageWithErrorHandler(
                                imageUrl: _currentUser!.profilePictureUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(_currentUser!.username),
                            subtitle: Text(_currentUser!.email),
                            onTap: _navigateToProfile,
                          )
                        : ListTile(
                            leading: const Icon(Icons.login),
                            title: const Text('Sign Up or Login'),
                            onTap: _showAuthModal,
                          ))
                    : const ProfileShimmer(),

                // "Manage Entities" ListTile
                ListTile(
                  leading: Icon(
                    Icons.account_tree,
                    color:
                        (!_isUserLoaded || !_isLoggedIn) ? Colors.grey : null,
                  ),
                  title: Text(
                    'Manage Entities',
                    style: (!_isUserLoaded || !_isLoggedIn)
                        ? const TextStyle(color: Colors.grey)
                        : null,
                  ),
                  onTap: _isUserLoaded && _isLoggedIn && _currentUser != null
                      ? () {
                          if (_currentUser != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserEntitiesScreen(
                                    userId: _currentUser!.id),
                              ),
                            );
                          } else {
                            _showAuthModal();
                          }
                        }
                      : null,
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
                                    const NotificationPreferencesScreen()),
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
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
                SizedBox(height: sectionSpacing),
              ],
            ),
          ),
          // Logout button at the bottom.
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 150,
                child: TextButton(
                  child: Text(
                    'Logout',
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                  onPressed: _handleSignOut,
                ),
              ),
            ),
        ],
      ),
      // FloatingActionButton for entity creation.
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

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if the current theme is dark or light.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode
        ? Colors.grey.shade700.withValues(alpha: 0.1)
        : Colors.grey.shade300;
    final highlightColor = isDarkMode
        ? Colors.grey.shade500.withValues(alpha: 0.1)
        : Colors.grey.shade100;
    final containerColor =
        isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListTile(
        leading: ClipOval(
          child: Container(
            width: 50,
            height: 50,
            color: containerColor,
          ),
        ),
        title: Container(
          width: double.infinity,
          height: 16.0,
          color: containerColor,
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4.0),
          width: double.infinity,
          height: 14.0,
          color: containerColor,
        ),
      ),
    );
  }
}
