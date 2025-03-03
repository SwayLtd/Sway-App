import 'package:url_launcher/url_launcher.dart';

/// Launches a URL if possible.
Future<void> launchURL(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw 'Could not launch $url';
  }
}
