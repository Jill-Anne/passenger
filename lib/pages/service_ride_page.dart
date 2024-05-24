import 'package:flutter/material.dart';
import 'package:passenger/pages/termsconditions_page.dart';

class ServiceRidePage extends StatelessWidget {
  String name;
  String phone;

  ServiceRidePage({
    super.key,
    required this.name,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back)),
            ),
            Image.asset(
              'assets/images/Capture1.PNG',
            ),
            Container(
              width: 275,
              margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10), // Adjusted margin for better spacing
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => TermsConditionsPage(
                                name: name,
                                phone: phone,
                              )));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: const Color(
                      0xFF2E3192), // Use the color from your reusable widget
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Terms and Condition ', // Custom text for the booking action
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
