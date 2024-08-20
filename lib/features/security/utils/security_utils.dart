// https://www.youtube.com/watch?v=2V90-4O9QOg - You're Flutter App Is Insecure Do This! - Improve Flutter Application Security - Hussain Mustafa
// https://www.youtube.com/watch?v=GJqfmmwhw-c - Flutter Secure Storage - Flutter Tutorial | Storing Data locally using Flutter Secure Storage - vijaycreations

// security_utils.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:root_jailbreak_sniffer/rjsniffer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityUtils extends StatefulWidget {
  const SecurityUtils({super.key});

  @override
  _SecurityUtilsState createState() => _SecurityUtilsState();
}

class _SecurityUtilsState extends State<SecurityUtils> {
  late bool amICompromised;
  late bool amIEmulator;
  late bool amIDebugged;

  @override
  void initState() {
    super.initState();
    checkOSDetection();
  }

  /// [checkOSDetection] Checks for Root and Jailbreak Detection
  Future<void> checkOSDetection() async {
    try {
      amICompromised =
          await Rjsniffer.amICompromised() ?? false; //Detect JailBreak and Root
      amIEmulator =
          await Rjsniffer.amIEmulator() ?? false; //Detect Emulator Environment
      amIDebugged =
          await Rjsniffer.amIDebugged() ?? false; //Detect being Debugged
    } on PlatformException {
      amICompromised = true;
      amIEmulator = true;
      amIDebugged = true;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class SecureStorage {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// [writeSecureData] Writes secure data to the device
  Future<void> writeSecureData(String key, String value) async {
    await storage.write(key: key, value: value);
  }

  /// [readSecureData] Reads secure data from the device
  Future<void> readSecureData(String key) async {
    final String value = await storage.read(key: key) ?? 'No data found!';
    debugPrint("Data read from secure storage: $value");
  }

  /// [deleteSecureData] Deletes secure data from the device
  Future<void> deleteSecureData(String key) async {
    await storage.delete(key: key);
  }
}
