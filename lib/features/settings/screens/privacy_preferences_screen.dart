import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Preferences'),
      ),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: const Text('Analytics Storage'),
            subtitle: const Text('Allow storage for analytics purposes'),
            value: _analyticsConsent,
            onChanged: (bool value) {
              setState(() {
                _analyticsConsent = value;
              });
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Ad Storage'),
            subtitle: const Text('Allow storage for advertising purposes'),
            value: _adStorageConsent,
            onChanged: (bool value) {
              setState(() {
                _adStorageConsent = value;
              });
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Ad User Data'),
            subtitle: const Text('Allow use of user data for ads'),
            value: _adUserDataConsent,
            onChanged: (bool value) {
              setState(() {
                _adUserDataConsent = value;
              });
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Ad Personalization'),
            subtitle: const Text('Allow personalized ads'),
            value: _adPersonalizationConsent,
            onChanged: (bool value) {
              setState(() {
                _adPersonalizationConsent = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
