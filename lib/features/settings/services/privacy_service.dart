import 'package:flutter/services.dart';

class PrivacyService {
  static const MethodChannel _channel = MethodChannel('consent_manager');

  Future<void> updateConsent({
    required bool analyticsConsent,
    required bool adStorageConsent,
    required bool adUserDataConsent,
    required bool adPersonalizationConsent,
  }) async {
    await _channel.invokeMethod('updateConsent', {
      'analyticsConsent': analyticsConsent,
      'adStorageConsent': adStorageConsent,
      'adUserDataConsent': adUserDataConsent,
      'adPersonalizationConsent': adPersonalizationConsent,
    });
  }
}
