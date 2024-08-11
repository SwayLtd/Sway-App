// notification_utils.dart

// ignore_for_file: avoid_print, unused_element

import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway_events/core/services/notification_service.dart';

class NotificationUtils extends StatefulWidget {
  @override
  _NotificationUtilsState createState() => _NotificationUtilsState();
}

class _NotificationUtilsState extends State<NotificationUtils> {
  final NotificationService _notificationService = NotificationService();
  String? _emailAddress;
  String? _smsNumber;
  String? _externalUserId;
  String? _language;
  String? _liveActivityId;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  void _handleSendTags() {
    try {
      print("Sending tags");
      OneSignal.User.addTagWithKey("test2", "val2");

      print("Sending tags array");
      final sendTags = {'test': 'value', 'test2': 'value2'};
      OneSignal.User.addTags(sendTags);
    } catch (e) {
      print('Error sending tags: $e');
    }
  }

  void _handleRemoveTag() {
    try {
      print("Deleting tag");
      OneSignal.User.removeTag("test2");

      print("Deleting tags array");
      OneSignal.User.removeTags(['test']);
    } catch (e) {
      print('Error removing tag: $e');
    }
  }

  Future<void> _handleGetTags() async {
    try {
      print("Get tags");

      final tags = await OneSignal.User.getTags();
      print(tags);
    } catch (e) {
      print('Error getting tags: $e');
    }
  }

  void _handlePromptForPushPermission() {
    try {
      print("Prompting for Permission");
      OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      print('Error prompting for push permission: $e');
    }
  }

  void _handleSetLanguage() {
    try {
      if (_language == null) return;
      print("Setting language");
      OneSignal.User.setLanguage(_language!);
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  void _handleSetEmail() {
    try {
      if (_emailAddress == null) return;
      print("Setting email");

      OneSignal.User.addEmail(_emailAddress!);
    } catch (e) {
      print('Error setting email: $e');
    }
  }

  void _handleRemoveEmail() {
    try {
      if (_emailAddress == null) return;
      print("Remove email");

      OneSignal.User.removeEmail(_emailAddress!);
    } catch (e) {
      print('Error removing email: $e');
    }
  }

  void _handleSetSMSNumber() {
    try {
      if (_smsNumber == null) return;
      print("Setting SMS Number");

      OneSignal.User.addSms(_smsNumber!);
    } catch (e) {
      print('Error setting SMS number: $e');
    }
  }

  void _handleRemoveSMSNumber() {
    try {
      if (_smsNumber == null) return;
      print("Remove smsNumber");

      OneSignal.User.removeSms(_smsNumber!);
    } catch (e) {
      print('Error removing SMS number: $e');
    }
  }

  void _handleConsent() {
    try {
      print("Setting consent to true");
      OneSignal.consentGiven(true);

      print("Setting state");
      setState(() {});
    } catch (e) {
      print('Error setting consent: $e');
    }
  }

  void _handleSetLocationShared() {
    try {
      print("Setting location shared to true");
      OneSignal.Location.setShared(true);
    } catch (e) {
      print('Error setting location shared: $e');
    }
  }

  Future<void> _handleGetExternalId() async {
    try {
      final externalId = await OneSignal.User.getExternalId();
      print('External ID: $externalId');
    } catch (e) {
      print('Error getting external ID: $e');
    }
  }

  void _handleLogin() {
    try {
      print("Setting external user ID");
      if (_externalUserId == null) return;
      OneSignal.login(_externalUserId!);
      OneSignal.User.addAlias("fb_id", "1341524");
    } catch (e) {
      print('Error logging in: $e');
    }
  }

  void _handleLogout() {
    try {
      OneSignal.logout();
      OneSignal.User.removeAlias("fb_id");
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Future<void> _handleGetOnesignalId() async {
    try {
      final onesignalId = await OneSignal.User.getOnesignalId();
      print('OneSignal ID: $onesignalId');
    } catch (e) {
      print('Error getting OneSignal ID: $e');
    }
  }

  // Does it need to be moved to NotificationUtils class?
  Future<void> oneSignalOutcomeExamples() async {
    try {
      OneSignal.Session.addOutcome("normal_1");
      OneSignal.Session.addOutcome("normal_2");

      OneSignal.Session.addUniqueOutcome("unique_1");
      OneSignal.Session.addUniqueOutcome("unique_2");

      OneSignal.Session.addOutcomeWithValue("value_1", 3.2);
      OneSignal.Session.addOutcomeWithValue("value_2", 3.9);
    } catch (e) {
      print('Error in oneSignalOutcomeExamples: $e');
    }
  }

  void _handleOptIn() {
    try {
      OneSignal.User.pushSubscription.optIn();
    } catch (e) {
      print('Error opting in: $e');
    }
  }

  void _handleOptOut() {
    try {
      OneSignal.User.pushSubscription.optOut();
    } catch (e) {
      print('Error opting out: $e');
    }
  }

  void _handleStartDefaultLiveActivity() {
    try {
      if (_liveActivityId == null) return;
      print("Starting default live activity");
      OneSignal.LiveActivities.startDefault(_liveActivityId!, {
        "title": "Welcome!",
      }, {
        "message": {"en": "Hello World!"},
        "intValue": 3,
        "doubleValue": 3.14,
        "boolValue": true,
      });
    } catch (e) {
      print('Error starting default live activity: $e');
    }
  }

  void _handleEnterLiveActivity() {
    try {
      if (_liveActivityId == null) return;
      print("Entering live activity");
      OneSignal.LiveActivities.enterLiveActivity(
        _liveActivityId!,
        "FAKE_TOKEN",
      );
    } catch (e) {
      print('Error entering live activity: $e');
    }
  }

  void _handleExitLiveActivity() {
    try {
      if (_liveActivityId == null) return;
      print("Exiting live activity");
      OneSignal.LiveActivities.exitLiveActivity(_liveActivityId!);
    } catch (e) {
      print('Error exiting live activity: $e');
    }
  }

  void _handleSetPushToStartLiveActivity() {
    try {
      if (_liveActivityId == null) return;
      print("Setting Push-To-Start live activity");
      OneSignal.LiveActivities.setPushToStartToken(
        _liveActivityId!,
        "FAKE_TOKEN",
      );
    } catch (e) {
      print('Error setting Push-To-Start live activity: $e');
    }
  }

  void _handleRemovePushToStartLiveActivity() {
    try {
      if (_liveActivityId == null) return;
      print("Removing Push-To-Start live activity");
      OneSignal.LiveActivities.removePushToStartToken(_liveActivityId!);
    } catch (e) {
      print('Error removing Push-To-Start live activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

typedef OnButtonPressed = void Function();

class OneSignalButton extends StatefulWidget {
  final String title;
  final OnButtonPressed onPressed;
  final bool enabled;

  const OneSignalButton(this.title, this.onPressed, this.enabled);

  @override
  State<StatefulWidget> createState() => OneSignalButtonState();
}

class OneSignalButtonState extends State<OneSignalButton> {
  @override
  Widget build(BuildContext context) {
    return Table(
      children: [
        TableRow(
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 212, 86, 83),
                disabledBackgroundColor: const Color.fromARGB(180, 212, 86, 83),
                padding: const EdgeInsets.all(8.0),
              ),
              onPressed: widget.enabled ? widget.onPressed : null,
              child: Text(widget.title),
            ),
          ],
        ),
        TableRow(
          children: [
            Container(
              height: 8.0,
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> sendNotification(String userId, String message) async {
  final response = await Supabase.instance.client.rpc(
    'send_notification',
    params: {
      'user_id': userId,
      'message': message,
    },
  );

  if (response.error != null) {
    print(
      "Erreur lors de l'envoi de la notification: ${response.error!.message}",
    );
  } else {
    print('Notification envoyée avec succès');
  }
}
