// https://www.walturn.com/insights/how-to-set-up-analytics-in-flutter-using-firebase
// https://stackoverflow.com/questions/76784297/how-to-ask-for-android-user-permission-for-analytics-on-flutter

// lib/features/settings/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;

  /// Logs an event when a user signs in with email/password.
  Future<void> logSignInWithEmailPassword({required String email}) async {
    await _firebaseAnalytics.logLogin(
      loginMethod: 'email', // Specifies the login method
      parameters: {
        'email': email, // Optional custom parameter
      },
    );
  }

  /// Logs an event when a user signs up with email/password.
  Future<void> logSignUpWithEmailPassword({required String email}) async {
    await _firebaseAnalytics.logSignUp(
      signUpMethod: 'email', // Specifies the sign-up method
      parameters: {
        'email': email, // Optional custom parameter
      },
    );
  }

  /// Logs a custom event with a given [name] and optional [parameters].
  ///
  /// Parameters:
  /// - [name]: The name of the custom event.
  /// - [parameters]: A map of key-value pairs containing event parameters.
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    final data = parameters ?? <String, dynamic>{};
    await _firebaseAnalytics.logEvent(
      name: name, // Event name as defined by you
      parameters: Map<String, Object>.from(data), // Event parameters
    );
  }

  /// Logs a predefined event for tracking a user's view of a specific screen.
  ///
  /// Parameters:
  /// - [screenName]: The name of the screen viewed.
  /// - [screenClass]: The class name of the screen (optional).
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _firebaseAnalytics.logScreenView(
      screenName: screenName, // Name of the screen
      screenClass: screenClass, // Class name of the screen
    );
  }

  /// Logs a predefined event for tracking a user making a purchase.
  ///
  /// Parameters:
  /// - [itemId]: The ID of the item purchased.
  /// - [itemName]: The name of the item purchased.
  /// - [value]: The monetary value of the purchase.
  /// - [currency]: The currency of the purchase (default is USD).
  Future<void> logPurchase({
    required String itemId,
    required String itemName,
    required double value,
    String currency = 'USD',
  }) async {
    await _firebaseAnalytics.logPurchase(
      value: value, // Purchase value
      currency: currency, // Currency code
      items: [
        AnalyticsEventItem(
          itemId: itemId, // Item ID
          itemName: itemName, // Item name
        ),
      ],
    );
  }

  /// Sets a user ID for the analytics session.
  ///
  /// Parameters:
  /// - [userId]: The user ID to set.
  Future<void> setUserId(String userId) async {
    await _firebaseAnalytics.setUserId(id: userId); // Sets the user ID
  }

  /// Sets a user property for the analytics session.
  ///
  /// Parameters:
  /// - [name]: The name of the user property.
  /// - [value]: The value of the user property.
  Future<void> setUserProperty(String name, String value) async {
    await _firebaseAnalytics.setUserProperty(
      name: name, // User property name
      value: value, // User property value
    );
  }
}
