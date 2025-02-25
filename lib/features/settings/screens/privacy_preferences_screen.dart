import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sway/features/settings/screens/privacy_policy_screen.dart';

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
  static const MethodChannel _consentChannel = MethodChannel('consent_manager');

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
                  subtitle: const Text('Authorize storage for analysis'),
                  value: _analyticsConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _analyticsConsent = value;
                    });
                    _updateConsent();
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Ad Storage'),
                  subtitle: const Text('Authorize storage for advertising'),
                  value: _adStorageConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _adStorageConsent = value;
                    });
                    _updateConsent();
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Ad User Data'),
                  subtitle: const Text(
                      'Authorize the use of user data for advertising purposes'),
                  value: _adUserDataConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _adUserDataConsent = value;
                    });
                    _updateConsent();
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Ad Personalization'),
                  subtitle: const Text('Allow ad personalization'),
                  value: _adPersonalizationConsent,
                  onChanged: (bool value) {
                    setState(() {
                      _adPersonalizationConsent = value;
                    });
                    _updateConsent();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () {
                MaterialPageRoute(builder: (context) => PrivacyPolicyScreen());
              },
              child: const Text('Privacy Policy'),
            ),
          ),
        ],
      ),
    );
  }
}
