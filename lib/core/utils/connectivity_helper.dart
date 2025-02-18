import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks whether the device is connected to the Internet.
Future<bool> isConnected() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}
