import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Service'),
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
                'Welcome to Tri.CO! By using our mobile application and services, you agree to the following Terms of Service. These terms govern your use of our platform and services as a passenger using the Tri.CO ride-sharing platform. If you do not agree to these terms, you may not use the services.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '2. Account Registration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'To use our services, you must create an account. When you create an account, you must provide accurate, current, and complete information. You agree to keep your account information updated.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '3. Booking a Ride',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'As a passenger, you can request rides via the Tri.CO platform. Once a driver accepts your ride request, the booking will be confirmed. You are responsible for ensuring that the information provided in your ride request (including the destination and time) is accurate.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '4. Payment Terms',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Tri.CO does not process payments through the app. All payments for rides are made outside the app, directly between the passenger and the driver. Therefore, Tri.CO does not charge for rides and does not handle refunds.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '5. Cancellations and Service Ride Changes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Tri.CO does not charge cancellation fees. If you need to cancel a ride, you must call the driver directly to cancel the service ride. Tri.CO is not responsible for cancellations made outside the platform.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '6. Limitation of Liability',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'In case of any personal issues, passengers are advised to report the incident directly to Tri.CO\'s President. The platform itself no longer handles such matters, as the driver’s actions are governed by the driver’s own rules and penalties as defined by Cotoda, the driver’s association.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '7. Dispute Resolution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'If you have a dispute with a driver or Tri.CO, you agree to attempt to resolve it directly with the driver. If the issue cannot be resolved, you may seek mediation, but Tri.CO is not obligated to get involved in private disputes. Disputes regarding driver conduct are handled according to Cotoda’s independent rules.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '8. Modifications to the Terms',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Tri.CO reserves the right to modify these Terms of Service at any time. Any changes will be posted on the platform, and you will be notified of updates when you log into your account.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '9. Governing Law',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'These Terms of Service are governed by the laws of the jurisdiction where Tri.CO operates. Any legal disputes related to the Terms will be settled in the applicable courts of that jurisdiction.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
