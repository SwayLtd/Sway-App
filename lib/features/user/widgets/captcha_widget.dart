// lib/widgets/captcha_widget.dart

import 'package:flutter/material.dart';

class CaptchaWidget extends StatefulWidget {
  final Function(String) onVerified;
  const CaptchaWidget({Key? key, required this.onVerified}) : super(key: key);

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  final String siteKey =
      'YOUR_HCAPTCHA_SITE_KEY'; // Replace with your hCaptcha site key

  @override
  Widget build(BuildContext context) {
    return Container();
    /*return HCaptcha(
      onVerified: (token) {
        widget.onVerified(token);
      },
      onError: (error) {
        // Handle errors if needed
        print('hCaptcha error: $error');
      },
      // Optionally, customize other properties
    );*/
  }
}
