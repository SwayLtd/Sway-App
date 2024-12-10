// lib/features/notification/screens/notification_preferences_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/core/services/notification_preferences_service.dart';
import 'package:sway/features/user/models/user_notification_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Remplacez par l'ID utilisateur actuel
    int userId =
        _currentUserId(); // Implémentez cette méthode pour récupérer l'ID réel
    UserNotificationPreferences prefs =
        await _preferencesService.getPreferences(userId);
    setState(() {
      _preferences = prefs;
    });
  }

  Future<void> _updatePreferences() async {
    if (_preferences == null) return;

    int userId = _preferences!.userId;
    await _preferencesService.updatePreferences(userId, _preferences!);
    // Optionnel : Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférences enregistrées avec succès')),
    );
  }

  int _currentUserId() {
    // Implémentez la logique pour récupérer l'ID utilisateur actuel
    // Par exemple, depuis le service utilisateur ou l'état global
    return 1; // Exemple : retournez l'ID réel
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences de Notification'),
      ),
      body: _preferences == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Notifications Événements'),
                  value: _preferences!.eventNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      _preferences =
                          _preferences!.copyWith(eventNotifications: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications Artistes'),
                  value: _preferences!.artistNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      _preferences =
                          _preferences!.copyWith(artistNotifications: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications Promoteurs'),
                  value: _preferences!.promoterNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      _preferences =
                          _preferences!.copyWith(promoterNotifications: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications Lieux'),
                  value: _preferences!.venueNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      _preferences =
                          _preferences!.copyWith(venueNotifications: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications Sociales'),
                  value: _preferences!.socialNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      _preferences =
                          _preferences!.copyWith(socialNotifications: value);
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _updatePreferences,
                    child: const Text('Enregistrer les Préférences'),
                  ),
                ),
              ],
            ),
    );
  }
}
