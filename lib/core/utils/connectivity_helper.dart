// lib/core/utils/connectivity_helper.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityHelper {
  /// Un stream qui émet l'état de la connexion réelle (vrai si Internet est accessible)
  static Stream<bool> get connectivityStream =>
      Connectivity().onConnectivityChanged.asyncMap((_) => hasInternet());

  /// Vérifie si Internet est accessible en effectuant une vérification active.
  static Future<bool> hasInternet() async {
    final customChecker = InternetConnectionChecker.createInstance(
      slowConnectionConfig: SlowConnectionConfig(
        enableToCheckForSlowConnection: true,
        slowConnectionThreshold: const Duration(seconds: 1),
      ),
    );
    return await customChecker.hasConnection;
  }

  /// Retourne l'état actuel de la connexion Internet.
  static Future<bool> getCurrentConnectivity() async {
    return await hasInternet();
  }
}

/// Checks whether the device is connected to the Internet.
Future<bool> isConnected() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}
