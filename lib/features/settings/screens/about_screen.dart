// lib/features/settings/screens/about_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sway/core/constants/dimensions.dart'; // sectionSpacing is defined here
import 'package:go_router/go_router.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  // Retrieve app version from pubspec.yaml using package_info_plus
  Future<void> _loadAppInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  // Request in-app review or redirect to the store if not available
  Future<void> _requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // TODO: Replace '<your_app_id>' with your actual app ID
      final Uri url = Uri.parse(
          'https://play.google.com/store/apps/details?id=<your_app_id>');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align all text to the left
            children: [
              // Logo and dynamic app version
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logotype_transparent.png',
                      fit: BoxFit.contain,
                      height: 28,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version $_version',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: sectionSpacing),
              // App description
              const Text(
                'Sway is a mobile event management application that helps users discover, organize, and manage events effortlessly. '
                'Sway aims to provide a seamless and intuitive experience for both event attendees and promoters.',
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: sectionSpacing),
              // Clickable links
              ListTile(
                title: const Text('Review our app'),
                onTap: _requestReview,
              ),
              ListTile(
                title: const Text('How it works'),
                onTap: () {
                  // TODO: Implement navigation to the "How it works" screen
                },
              ),
              ListTile(
                title: const Text('About us'),
                onTap: () {
                  // TODO: Implement navigation to the "About us" screen
                },
              ),
              ListTile(
                title: const Text('Jobs'),
                onTap: () {
                  // TODO: Implement navigation to the "Jobs" screen
                },
              ),
              ListTile(
                title: const Text('Terms'),
                onTap: () {
                  // Using GoRouter for navigation instead of Navigator.pushNamed to avoid onGenerateRoute error
                  context.push('/termsAndConditions');
                },
              ),
              ListTile(
                title: const Text('Privacy'),
                onTap: () {
                  context.push('/privacyPolicy');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
