// lib/features/user/screens/terms_and_conditions_screen.dart

import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  /// Builds the UI for the Terms and Conditions screen with fake content.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            '''
**Terms and Conditions**

Welcome to Sway! These terms and conditions outline the rules and regulations for the use of our application.

**1. Introduction**
By accessing this app, you agree to be bound by these Terms and Conditions.

**2. User Responsibilities**
Users must provide accurate information during registration and maintain the confidentiality of their credentials.

**3. Privacy Policy**
We value your privacy and ensure that your data is protected. Please refer to our Privacy Policy for more details.

**4. Limitation of Liability**
Sway shall not be held liable for any damages arising from the use of this application.

**5. Changes to Terms**
We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting.

**6. Contact Us**
If you have any questions about these Terms and Conditions, please contact us at contact@sway.events.

Thank you for using Sway!
            ''',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
