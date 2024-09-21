import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  double leftPadding = 20.0;
  double topPadding = 0;
  double rightPadding = 30.0;
  double bottomPadding = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPadding, topPadding, rightPadding, bottomPadding),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '1. Introduction\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Welcome to Tri.CO. These terms and conditions govern your access to and use of the Tri.CO service ride platform, which facilitates direct communications between passengers and drivers after a ride request has been confirmed.\n\n',
                  ),
                  TextSpan(
                    text: '2. Platform Usage\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Users must create and maintain an active personal user account to request or offer a ride. Account registration requires submission of personal information as specified in our privacy policy.\n'
                        'By using Tri.CO, you agree to communicate directly with your counterparty (driver or passenger) regarding the specifics of each ride once a booking is confirmed.\n\n',
                  ),
                  TextSpan(
                    text: '3. Booking and Scheduling\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Passengers can book rides for specific dates and times via Tri.CO.\n'
                        'Acceptance of ride requests is at the discretion of the drivers, based on their availability and willingness to fulfill the ride requirements.\n\n',
                  ),
                  TextSpan(
                    text: '4. Direct Communication\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Upon the acceptance of a ride request, all further details pertaining to the service ride must be communicated directly between the passenger and the driver.\n'
                        'Tri.CO is not responsible for the content, accuracy, or timeliness of communications between users.\n\n',
                  ),
                  TextSpan(
                    text: '5. Payments\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'The payment terms, including the amount, payment method, and timing, will be directly agreed upon between the passenger and the driver.\n'
                        'Tri.CO does not facilitate or process payments, nor does it hold responsibility for any payment issues that may arise.\n\n',
                  ),
                  TextSpan(
                    text: '6. Responsibilities of Parties\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Passengers must provide detailed and accurate information regarding their ride needs.\n'
                        'Drivers commit to providing the agreed-upon service as coordinated directly with the passenger.\n'
                        'Both parties must behave in a professional and respectful manner throughout their interaction.\n\n',
                  ),
                  TextSpan(
                    text: '7. Dispute Resolution\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Passengers and drivers are encouraged to resolve disputes amicably among themselves.\n'
                        'Tri.CO may provide mediation assistance as a courtesy but is not obligated to participate in dispute resolution.\n\n',
                  ),
                  TextSpan(
                    text: '8. Limitation of Liability\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Tri.CO shall not be liable for any direct, indirect, incidental, special, or consequential damages resulting from the use of the platform or as a result of direct agreements made between users.\n\n',
                  ),
                  TextSpan(
                    text: '9. Amendments\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Tri.CO reserves the right to modify these terms and conditions at any time. Changes will become effective immediately upon posting on the platform.\n\n',
                  ),
                  TextSpan(
                    text: '10. Governing Law\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'These terms and conditions are governed by the laws of the jurisdiction in which Tri.CO operates.\n\n',
                  ),
                  TextSpan(
                    text: 'Acceptance of Terms\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'By using Tri.CO, you agree to be bound by these terms and conditions. If you do not accept these terms, you should not use the services provided by Tri.CO.',
                  ),
                ],
              ),
              textAlign: TextAlign.justify, // Justify the text
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
