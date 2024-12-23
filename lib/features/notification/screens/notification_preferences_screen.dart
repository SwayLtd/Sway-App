// lib/features/notification/screens/notification_preferences_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/features/notification/models/user_notification_preferences_model.dart';
import 'package:sway/features/notification/services/notification_preferences_service.dart';
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
      if (!mounted) return;
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

    if (!mounted) return;
    if (prefs != null) {
      setState(() => _preferences = prefs);
    } else {
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
      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Preferences saved successfully'),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error saving preferences'),
        ),
      );
    }
  }

  /// Ouvre un showTimePicker pour définir heures et minutes.
  /// On stocke le total en minutes dans 'ticketReminderHours'.
  Future<void> _pickReminderTime() async {
    if (_preferences == null) return;

    // Convertir le champ ticketReminderHours (en minutes) en TimeOfDay
    final currentTotalMinutes =
        _preferences!.ticketReminderHours.clamp(0, 24 * 60);
    final initialHour = (currentTotalMinutes ~/ 60) % 24; // heure entre 0 et 23
    final initialMinute = currentTotalMinutes % 60;

    final pickedTime = await showTimePicker(
      context: context,
      cancelText: '',
      confirmText: 'Set',
      helpText: '',
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      initialEntryMode: TimePickerEntryMode.dial,
      // Pas de builder ici
    );

    if (pickedTime != null) {
      // Calculer le total de minutes
      final newTotalMinutes = pickedTime.hour * 60 + pickedTime.minute;

      final updatedPreferences = _preferences!.copyWith(
        ticketReminderHours: newTotalMinutes,
      );

      setState(() => _preferences = updatedPreferences);
      _updatePreferences(updatedPreferences);
    }
  }

  /// Convertit le total de minutes en format "Xh Ym".
  String _formatTicketReminder(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
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
                // ----- Exemples existants -----
                SwitchListTile.adaptive(
                  title: const Text('Ticket Notifications'),
                  value: _preferences!.ticketNotifications,
                  onChanged: (bool value) {
                    final updated =
                        _preferences!.copyWith(ticketNotifications: value);
                    setState(() => _preferences = updated);
                    _updatePreferences(updated);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Event Notifications'),
                  value: _preferences!.eventNotifications,
                  onChanged: (bool value) {
                    final updated =
                        _preferences!.copyWith(eventNotifications: value);
                    setState(() => _preferences = updated);
                    _updatePreferences(updated);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Artist Notifications'),
                  value: _preferences!.artistNotifications,
                  onChanged: (bool value) {
                    final updated =
                        _preferences!.copyWith(artistNotifications: value);
                    setState(() => _preferences = updated);
                    _updatePreferences(updated);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Promoter Notifications'),
                  value: _preferences!.promoterNotifications,
                  onChanged: (bool value) {
                    final updated =
                        _preferences!.copyWith(promoterNotifications: value);
                    setState(() => _preferences = updated);
                    _updatePreferences(updated);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Venue Notifications'),
                  value: _preferences!.venueNotifications,
                  onChanged: (bool value) {
                    final updated =
                        _preferences!.copyWith(venueNotifications: value);
                    setState(() => _preferences = updated);
                    _updatePreferences(updated);
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Social Notifications'),
                  value: _preferences!.socialNotifications,
                  onChanged: (bool value) {
                    final updated =
                        _preferences!.copyWith(socialNotifications: value);
                    setState(() => _preferences = updated);
                    _updatePreferences(updated);
                  },
                ),

                // ----- Nouveau ListTile pour heure + minutes -----
                ListTile(
                  title: const Text('Ticket notification before event'),
                  trailing: Text(
                      _formatTicketReminder(_preferences!.ticketReminderHours)),
                  onTap: _pickReminderTime,
                ),
              ],
            ),
    );
  }
}
