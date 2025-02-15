// lib/features/user/screens/terms_and_conditions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  final String termsAndConditions = '''
# Sway Terms and Conditions

_Last updated: 15 February 2025_  
_Effective as of: 1 January 2025_

Welcome to Sway! These Terms and Conditions (“Agreement”) govern your access to and use of the Sway mobile application, website, and any related services (collectively, the “Platform”). By using Sway, you agree to be bound by this Agreement. If you do not agree with any part of these terms, please do not use our Platform.

## 1. Definitions

- **Sway**: The mobile event management application that helps users discover, organize, and manage events effortlessly.
- **User**: Any natural person using Sway as an event attendee or Organizer.
- **Event**: Any public or private event, festival, concert, or gathering listed or managed through Sway.
- **Organizer**: Any individual or entity that creates, promotes, or manages an Event on Sway.
- **Ticket**: A digital or physical voucher that grants access to an Event.
- **Platform**: The Sway mobile application, website, and related services.
- **Account**: The personalized digital environment provided by Sway to registered Users.
- **Service Fees**: Any fees charged by Sway for processing or service delivery.
- **Privacy Policy**: Sway’s policy governing the collection, use, and protection of your personal data (refer to our Privacy Policy for details).

## 2. General Use

### 2.1 Acceptance of Terms
By accessing and using Sway, you accept and agree to comply with these Terms and Conditions and any modifications that may be made in the future.

### 2.2 User Eligibility
Sway is intended for individuals who are of legal age in their jurisdiction. By using the Platform, you represent that you have the legal capacity to enter into this Agreement.

## 3. Platform Services

### 3.1 Description
Sway provides a mobile and web-based platform for discovering, organizing, and managing events. This includes functionalities for event promotion, ticket sales, and community engagement.

### 3.2 User Accounts
To access certain features, you must create an Account. You agree to provide accurate and current information during registration and to update such information as necessary.

### 3.3 Event Management and Ticketing
- **For Attendees**: Sway allows you to browse and purchase Tickets. The purchase of a Ticket constitutes a binding agreement between you and the event Organizer.
- **For Organizers**: You may list Events, manage Ticket sales, and access promotional tools. You are solely responsible for the accuracy of Event information and compliance with all applicable laws.

## 4. Payment and Refunds

### 4.1 Payment Processing
Payments for Tickets are processed through trusted third-party providers, such as Stripe. By purchasing Tickets, you agree to the terms and conditions of these providers.

### 4.2 Refunds and Cancellations
Tickets purchased via Sway are generally non-refundable unless an Event is cancelled or rescheduled. Currently, there are no exceptions for refunds beyond these circumstances.

## 5. User Responsibilities

### 5.1 Accuracy of Information
You are responsible for maintaining the confidentiality of your Account credentials and for all activities that occur under your Account.

### 5.2 Prohibited Conduct
You agree not to:
- Violate any applicable laws or regulations.
- Use Sway for fraudulent or unauthorized purposes.
- Engage in behavior that disrupts the functioning of the Platform or infringes on the rights of others.

## 6. Limitation of Liability

Sway provides the Platform on an “as is” basis. Sway shall not be liable for any indirect, incidental, or consequential damages resulting from your use of the Platform, except where such liability cannot be excluded by law. Nothing in this Agreement limits Sway’s liability for damages caused by intent, gross negligence, or willful misconduct.

## 7. Modifications to the Agreement

Sway reserves the right to modify these Terms and Conditions at any time. Notice of material changes will be provided through the Platform or via email at least 30 days before the changes take effect, allowing you the opportunity to terminate your Account if you do not accept the modifications. Continued use of Sway after the changes are posted constitutes acceptance of the new terms.

## 8. Intellectual Property

All content on Sway, including software, graphics, logos, and text, is the property of Sway or its licensors and is protected by applicable intellectual property laws. You agree not to reproduce, distribute, or create derivative works without explicit permission.

## 9. Privacy

Your use of Sway is governed by our Privacy Policy, which explains how we collect, use, and protect your personal information. By using Sway, you consent to the practices described in our Privacy Policy.

## 10. Dispute Resolution and Governing Law

### 10.1 Governing Law
This Agreement is governed by and construed in accordance with Belgian law.

### 10.2 Dispute Resolution
In the event of any dispute, you agree to attempt to resolve the matter amicably through our support channels before resorting to legal action. Any unresolved disputes shall be submitted to the competent courts in Belgium.

## 11. Termination

Sway reserves the right to suspend or terminate your Account and access to the Platform if you breach any part of this Agreement or for any other reason, at our sole discretion.

## 12. Contact Information

For any questions regarding these Terms and Conditions, please contact us at:
- **Email:** contact@sway.events
- **Mail:** Rue de l'Hocaile 5/602, 1348 Louvain-la-Neuve, Belgium

Thank you for choosing Sway!
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Markdown(
          data: termsAndConditions,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      ),
    );
  }
}
