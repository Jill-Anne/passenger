import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        leading: BackButton(),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Introduction',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'At Tri.CO, we value your privacy and are committed to protecting the personal information you share with us. This Privacy Policy outlines how we collect, use, and protect your data when you use our services.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '2. Information We Collect',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'We collect the following types of information when you use our services:\n\n- Personal Information: When you register or use our app, we collect your name, email address, phone number, and other details necessary for your account.\n- Ride Information: Details about your ride requests, including destination, pickup, time, and driver ratings.\n- Location Data: We collect real-time location data to provide accurate ride matching and navigation services.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '3. How We Use Your Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Your information is used for the following purposes:\n\n- To provide services: We use your information to facilitate ride bookings.\n- For communication: We may contact you with updates and service-related information.\n- To improve our services: We use usage data and feedback to improve the app and enhance user experience.\n- For safety: We use location data to provide accurate ride tracking and ensure safety during trips.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '4. Sharing Your Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Tri.CO does not share your personal information with third parties, except in the following cases:\n\n- With Drivers: To facilitate ride bookings, we share your name, phone number, and location with drivers.\n- With Service Providers: We may share information with third-party service providers who assist with app maintenance and other functions necessary to operate our platform.\n- As Required by Law: We may disclose your information in response to legal requests, such as subpoenas, court orders, or to comply with applicable laws.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '5. Data Security',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'We use industry-standard security measures to protect your personal data, including encryption, firewalls, and secure servers.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              // Adding the Data Retention Section
              Text(
                '6. Data Retention',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'We retain your personal information for as long as necessary to provide you with our services, comply with legal obligations, resolve disputes, and enforce our agreements. In accordance with industry standards, we retain ride data and personal information for a period of **6 months to 3 years**, after which the data will be securely deleted or anonymized. This period may vary depending on local regulations and specific business requirements.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '7. Your Rights and Choices',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'You have the right to:\n- Access and update: You can view and update your personal information at any time through the app.\n- Delete your account: If you wish to delete your account, you can do so by contacting us.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '8. Children\'s Privacy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Tri.CO is not intended for use by children under the age of 13. We do not knowingly collect personal information from children. If you believe we have collected such information, please contact us, and we will take steps to delete it.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '9. Changes to the Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'We may update this Privacy Policy from time to time. Any changes will be posted on this page, and the revised policy will be effective as soon as it is posted.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '10. Contact Us',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'If you have any questions or concerns about this Privacy Policy, please contact us at:\n\nEmail: support@tricorides.com\nPhone: +(63) 9123-4567',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
