import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.teal,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              'Effective Date: December 2024\n\n'
              'We value your privacy. This Privacy Policy explains how we collect, use, and protect your personal information when you use our app.\n\n'
              '1. Information Collection\n\n'
              'We may collect personal information such as your name, email address, and usage data when you use the app.\n\n'
              '2. Use of Information\n\n'
              'The information we collect is used to improve our services and provide a personalized experience.\n\n'
              '3. Data Protection\n\n'
              'We implement industry-standard security measures to protect your personal information.\n\n'
              '4. Third-Party Services\n\n'
              'We do not share your personal data with third parties, except as necessary to provide our services.\n\n'
              '5. Changes to This Policy\n\n'
              'We may update this Privacy Policy from time to time. Any changes will be posted on this page with the updated date.\n\n'
              '6. Contact Us\n\n'
              'If you have any questions about this Privacy Policy, please contact us at support@example.com.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
