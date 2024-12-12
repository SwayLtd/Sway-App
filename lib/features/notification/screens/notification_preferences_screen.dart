// lib/features/notification/screens/notification_preferences_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/features/notification/services/notification_preferences_service.dart';
import 'package:sway/features/user/models/user_notification_preferences.dart';
import 'package:sway/features/user/services/user_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  _NotificationPreferencesScreenState createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  UserNotificationPreferences? _preferences;
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Loads the notification preferences for the current user.
  Future<void> _loadPreferences() async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      // Handle unauthenticated user (redirect to login, show a message, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('User not authenticated'),
        ),
      );
      return;
    }
    final userId = currentUser.id;
    final prefs = await _preferencesService.getPreferences(userId);
    if (prefs != null) {
      setState(() {
        _preferences = prefs;
      });
    } else {
      // Handle the case where preferences could not be loaded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to load preferences'),
        ),
      );
    }
  }

  /// Updates the notification preferences in real-time.
  Future<void> _updatePreferences(
      UserNotificationPreferences updatedPreferences) async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      // Handle unauthenticated user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('User not authenticated'),
        ),
      );
      return;
    }
    final userId = currentUser.id;
    final success =
        await _preferencesService.updatePreferences(userId, updatedPreferences);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Preferences saved successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error saving preferences'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: _preferences == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Event Notifications'),
                  value: _preferences!.eventNotifications,
                  onChanged: (bool value) {
                    final updatedPreferences = _preferences!.copyWith(
                      eventNotifications: value,
                    );
                    setState(() {
                      _preferences = updatedPreferences;
                    });
                    _updatePreferences(updatedPreferences);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Artist Notifications'),
                  value: _preferences!.artistNotifications,
                  onChanged: (bool value) {
                    final updatedPreferences = _preferences!.copyWith(
                      artistNotifications: value,
                    );
                    setState(() {
                      _preferences = updatedPreferences;
                    });
                    _updatePreferences(updatedPreferences);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Promoter Notifications'),
                  value: _preferences!.promoterNotifications,
                  onChanged: (bool value) {
                    final updatedPreferences = _preferences!.copyWith(
                      promoterNotifications: value,
                    );
                    setState(() {
                      _preferences = updatedPreferences;
                    });
                    _updatePreferences(updatedPreferences);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Venue Notifications'),
                  value: _preferences!.venueNotifications,
                  onChanged: (bool value) {
                    final updatedPreferences = _preferences!.copyWith(
                      venueNotifications: value,
                    );
                    setState(() {
                      _preferences = updatedPreferences;
                    });
                    _updatePreferences(updatedPreferences);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Social Notifications'),
                  value: _preferences!.socialNotifications,
                  onChanged: (bool value) {
                    final updatedPreferences = _preferences!.copyWith(
                      socialNotifications: value,
                    );
                    setState(() {
                      _preferences = updatedPreferences;
                    });
                    _updatePreferences(updatedPreferences);
                  },
                ),
                // Le bouton "Save Preferences" n'est plus nécessaire car les modifications sont enregistrées en temps réel
              ],
            ),
    );
  }
}
