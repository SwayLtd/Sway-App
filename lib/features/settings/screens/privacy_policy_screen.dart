// lib/features/user/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  final String privacyPolicy = '''
# Sway Privacy Policy

_Last updated: 15 February 2025_

## 1. Introduction

Welcome to Sway. This Privacy Policy explains how Sway ("we", "our", or "us") collects, uses, discloses, and protects your personal data when you use our mobile application, website, and related services (the "Platform"). By accessing or using Sway, you agree to the terms of this Privacy Policy. If you do not agree with this Policy, please do not use our Platform.

Sway is operated by Régis André, an independent complementary operator based in Belgium, under the enterprise number BE1017816446.

## 2. Definitions

- **Personal Data**: Any information relating to an identified or identifiable natural person.
- **User**: Any individual who accesses or uses the Platform, including event attendees and Organizers.
- **Platform**: The Sway mobile application, website, and any related services.
- **Account**: The personalized digital environment provided by Sway to registered Users.
- **Cookies**: Small text files stored on your device to improve your user experience and analyze usage.
- **Legal Basis**: The basis on which we process your personal data, such as your consent, performance of a contract, legal obligation, or legitimate interest.

## 3. Data Collection and Processing

### 3.1 Types of Data We Collect

We may collect, process, and store various types of personal data, including:

- **Account Information**: Name, email address, date of birth, and contact details provided during registration.
- **Event Data**: Information related to events you browse, attend, or organize, such as event preferences and ticket purchase history.
- **Payment Data**: Payment method details (processed by our payment provider, e.g., Stripe), billing information, and transaction history.
- **Usage Data**: Data collected via cookies, pixels, and similar technologies, such as IP address, device information, and browsing behavior.
- **Support Data**: Any information you provide when contacting our support team.

### 3.2 Purposes and Legal Basis for Processing

We process your personal data for the following purposes and on the respective legal bases:

- **Account Management** (Performance of the Contract): To create and maintain your Account.
- **Provision of Services** (Performance of the Contract): To deliver and improve the Platform and related services.
- **Payment Processing** (Performance of the Contract): To process transactions using our payment provider.
- **Marketing and Communication** (Consent/Legitimate Interest): To send you updates and promotional information. You may withdraw your consent at any time.
- **Analytics and Improvement** (Legitimate Interest): To analyze usage patterns and improve our services.
- **Legal Compliance** (Legal Obligation): To comply with our obligations under applicable laws.

## 4. Data Sharing, Transfers and Processors

We may share your personal data with:

- **Service Providers**: Third parties that process data on our behalf, including:
  - **Supabase** for database hosting.
  - **Google** for managing internal company files.
  - **Stripe** for payment processing.
  - **Plausible** for analytics.
- **Legal Authorities**: When required by law or necessary to protect our rights.
- **Business Partners**: In aggregated or anonymized form for analytical and marketing purposes.

Your personal data may be transferred outside the European Economic Area (EEA) only if appropriate safeguards are in place, such as standard contractual clauses.

## 5. Data Retention

We retain your personal data only for as long as necessary to fulfill the purposes for which it was collected or as required by law. For example:
- Accounting and tax-related data may be stored for at least 10 years.
- Other personal data may be retained for 5 years after your last interaction with the Platform.

## 6. Your Rights

Under applicable data protection laws, you have certain rights regarding your personal data. These include:
- **Access**: Request a copy of your personal data.
- **Rectification**: Request correction of inaccurate or incomplete data.
- **Erasure**: Request deletion of your personal data under certain conditions.
- **Restriction**: Request limitation of processing of your data.
- **Data Portability**: Request transfer of your data in a structured, commonly used format.
- **Objection**: Object to the processing of your personal data for specific purposes.
- **Complaints**: File a complaint with a supervisory authority if you believe your data protection rights have been violated.

To exercise these rights, please contact us at the email provided in section 10.

## 7. Cookies and Tracking Technologies

We use cookies and similar tracking technologies to enhance your experience on our Platform. Cookies help us:
- Remember your preferences.
- Analyze website traffic.
- Provide personalized content and advertisements.

You can manage your cookie preferences through your browser settings. However, disabling cookies may affect your experience on our Platform.

## 8. Security

We implement appropriate technical, organizational, and physical measures to safeguard your personal data against unauthorized access, alteration, disclosure, or destruction. Despite these efforts, no method of transmission over the Internet is completely secure, and we cannot guarantee absolute security.

## 9. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in our practices or legal obligations. If material changes are made, we will notify you via the Platform or by email at least 15 days before the changes take effect. For any update, deletion, or modification of your personal data, please contact us at the email below.

## 10. Contact Information

If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:

Sway  
Operated by Régis André (Independent Complementary)  
Rue de l'Hocaile 5/602, 1348 Louvain-la-Neuve, Belgium  
Enterprise number: BE1017816446  
E-mail: contact@sway.events
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Markdown(
          data: privacyPolicy,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      ),
    );
  }
}
