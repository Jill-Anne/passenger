import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passenger/pages/termsconditions_page.dart';
import 'package:passenger/widgets/servicerideText.dart';

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

        // Set the status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123), // Set a color or transparent
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
  body: SafeArea(
    child: SingleChildScrollView(
      child: Column(
        children: [
          // Wrap the Row in a Container to set the background color
          Container(
            color: Color.fromARGB(255, 1, 42, 123), // Set background color to blue
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 10.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white), // Change icon color to white for visibility
                  ),
                  const SizedBox(
                      width: 10), // Adjust this value for desired space
                  const Text(
                    'Service Ride Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,  // Change text color to white for visibility
                    ),
                    ),
                  ],
                ),
              ),
          ),
              ServiceRideInfo(),
              Container(
                width: 275,
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        ),
                      ),
                    );
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
                        'View Terms and Condition', // Custom text for the booking action
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
      ),
    );
  }
}
