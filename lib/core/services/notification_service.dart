// notification_service.dart

// ignore_for_file: avoid_print

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  Future<void> initialize() async {
    try {
      // CHANGE THIS parameter to true if you want to test GDPR privacy consent
      const bool requireConsent = false;

      // Remove this method to stop OneSignal Debugging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      OneSignal.consentRequired(requireConsent);

      OneSignal.initialize(
        dotenv.env['ONESIGNAL_APP_ID']!,
      );

      OneSignal.LiveActivities.setupDefault();
      // OneSignal.LiveActivities.setupDefault(options: new LiveActivitySetupOptions(enablePushToStart: false, enablePushToUpdate: true));

      // AndroidOnly stat only
      // OneSignal.Notifications.removeNotification(1);
      // OneSignal.Notifications.removeGroupedNotifications("group5");

      OneSignal.Notifications.clearAll();

      OneSignal.Notifications.requestPermission(true);

      OneSignal.User.pushSubscription.addObserver((state) {
        print(OneSignal.User.pushSubscription.optedIn);
        print(OneSignal.User.pushSubscription.id);
        print(OneSignal.User.pushSubscription.token);
        print(state.current.jsonRepresentation());
      });

      OneSignal.User.addObserver((state) {
        final userState = state.jsonRepresentation();
        print('OneSignal user changed: $userState');
      });

      OneSignal.Notifications.addPermissionObserver((state) {
        print("Has permission $state");
      });

      OneSignal.Notifications.addClickListener((event) {
        print('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print(
          'NOTIFICATION WILL DISPLAY LISTENER CALLED WITH: ${event.notification.jsonRepresentation()}',
        );

        /// Display Notification, preventDefault to not display
        event.preventDefault();

        /// Do async work

        /// notification.display() to display after preventing default
        event.notification.display();
      });

      OneSignal.InAppMessages.addClickListener((event) {});

      OneSignal.InAppMessages.addWillDisplayListener((event) {
        print("ON WILL DISPLAY IN APP MESSAGE ${event.message.messageId}");
      });

      OneSignal.InAppMessages.addDidDisplayListener((event) {
        print("ON DID DISPLAY IN APP MESSAGE ${event.message.messageId}");
      });

      OneSignal.InAppMessages.addWillDismissListener((event) {
        print("ON WILL DISMISS IN APP MESSAGE ${event.message.messageId}");
      });

      OneSignal.InAppMessages.addDidDismissListener((event) {
        print("ON DID DISMISS IN APP MESSAGE ${event.message.messageId}");
      });

      // Some examples of how to use In App Messaging public methods with OneSignal SDK
      await oneSignalInAppMessagingTriggerExamples();

      // Some examples of how to use Outcome Events public methods with OneSignal SDK
      await oneSignalOutcomeExamples();

      OneSignal.InAppMessages.paused(true);
    } catch (e) {
      print('Error initializing platform state: $e');
    }
  }

  Future<void> oneSignalInAppMessagingTriggerExamples() async {
    try {
      /// Example addTrigger call for IAM
      /// This will add 1 trigger so if there are any IAM satisfying it, it
      /// will be shown to the user
      OneSignal.InAppMessages.addTrigger("trigger_1", "one");

      /// Example addTriggers call for IAM
      /// This will add 2 triggers so if there are any IAM satisfying these, they
      /// will be shown to the user
      final Map<String, String> triggers = <String, String>{};
      triggers["trigger_2"] = "two";
      triggers["trigger_3"] = "three";
      OneSignal.InAppMessages.addTriggers(triggers);

      // Removes a trigger by its key so if any future IAM are pulled with
      // these triggers they will not be shown until the trigger is added back
      OneSignal.InAppMessages.removeTrigger("trigger_2");

      // Create a list and bulk remove triggers based on keys supplied
      final List<String> keys = ["trigger_1", "trigger_3"];
      OneSignal.InAppMessages.removeTriggers(keys);
    } catch (e) {
      print('Error in oneSignalInAppMessagingTriggerExamples: $e');
    }
  }

  Future<void> oneSignalOutcomeExamples() async {
    try {
      // Example code for Outcome Events
    } catch (e) {
      print('Error in oneSignalOutcomeExamples: $e');
    }
  }
}
