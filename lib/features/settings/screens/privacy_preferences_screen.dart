import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPreferencesScreen extends StatefulWidget {
  const PrivacyPreferencesScreen({Key? key}) : super(key: key);

  @override
  _PrivacyPreferencesScreenState createState() =>
      _PrivacyPreferencesScreenState();
}

class _PrivacyPreferencesScreenState extends State<PrivacyPreferencesScreen> {
  bool _analyticsConsent = false;
  bool _adStorageConsent = false;
  bool _adUserDataConsent = false;
  bool _adPersonalizationConsent = false;

  // Création du channel pour communiquer avec le code natif
  static const MethodChannel _consentChannel =
      MethodChannel('consent_manager');

  /// Appelle la méthode native pour mettre à jour le consentement
  Future<void> _updateConsent() async {
    try {
      await _consentChannel.invokeMethod('updateConsent', {
        'analyticsConsent': _analyticsConsent,
        'adStorageConsent': _adStorageConsent,
        'adUserDataConsent': _adUserDataConsent,
        'adPersonalizationConsent': _adPersonalizationConsent,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consentement mis à jour')),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Preferences'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Analytics Storage'),
                  subtitle:
                      const Text('Autoriser le stockage pour les analyses'),
                  value: _analyticsConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _analyticsConsent = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Ad Storage'),
                  subtitle:
                      const Text('Autoriser le stockage pour la publicité'),
                  value: _adStorageConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _adStorageConsent = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Ad User Data'),
                  subtitle: const Text('Autoriser l’utilisation des données utilisateur pour la pub'),
                  value: _adUserDataConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _adUserDataConsent = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Ad Personalization'),
                  subtitle: const Text('Autoriser la personnalisation des publicités'),
                  value: _adPersonalizationConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _adPersonalizationConsent = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Bouton placé en bas pour déclencher la mise à jour du consentement
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: _updateConsent,
              child: const Text('Mettre à jour le consentement'),
            ),
          ),
        ],
      ),
    );
  }
}
