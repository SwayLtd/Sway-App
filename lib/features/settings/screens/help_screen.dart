// lib/features/settings/screens/help_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  /// Builds a help card with a title, description, and a custom-styled button.
  Widget _buildHelpCard({
    required BuildContext context,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            // Description (with bold email where needed)
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: _parseDescription(description),
              ),
            ),
            const SizedBox(height: 16.0),
            // Action button using a style similar to your snippet.
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText.toUpperCase()),
            )
          ],
        ),
      ),
    );
  }

  /// Parses a description string that can include "**" to bold text.
  List<TextSpan> _parseDescription(String description) {
    // This simple parser splits by '**' and alternates bold and normal text.
    final parts = description.split('**');
    return List<TextSpan>.generate(parts.length, (index) {
      return TextSpan(
        text: parts[index],
        style: index % 2 == 1
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      );
    });
  }

  /// Launches a URL if possible.
  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHelpCard(
              context: context,
              title: 'Have a Question?',
              description:
                  'For any inquiries, you can email **contact@sway.events**.',
              buttonText: 'Send an Email',
              onPressed: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'contact@sway.events',
                  queryParameters: {'subject': 'Inquiry from App'},
                );
                await _launchURL(emailLaunchUri);
              },
            ),
            _buildHelpCard(
              context: context,
              title: 'Instagram',
              description:
                  'Follow **@app.sway** on Instagram to stay updated with our latest news!',
              buttonText: 'Follow @app.sway',
              onPressed: () async {
                final Uri instaUri =
                    Uri.parse('https://instagram.com/app.sway');
                await _launchURL(instaUri);
              },
            ),
            _buildHelpCard(
              context: context,
              title: 'Website',
              description:
                  'Visit our website to learn more about Sway and our services.',
              buttonText: 'Visit Website',
              onPressed: () async {
                final Uri websiteUri = Uri.parse('https://www.sway.events');
                await _launchURL(websiteUri);
              },
            ),
          ],
        ),
      ),
    );
  }
}
