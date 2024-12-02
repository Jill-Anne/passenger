import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceRideInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    // Set the status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123), // Set a color or transparent
      statusBarIconBrightness: Brightness.light,
    ));

    return const Padding(
      padding: EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is a Service Ride?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          SizedBox(height: 5),
          Text(
            'Service rides offer flexible booking, allowing you to book a ride for one or multiple days. '
            'You can also schedule rides for specific dates and times in advance.',
            textAlign: TextAlign.justify,
           // style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(height: 16),
          
          Text(
            'Setting Up Your Service Ride',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          SizedBox(height: 5),
          Text(
            'First, select your start and end dates on the calendar, then specify the times you need the ride each day. '
            'After that, provide your pickup location, or destination.',
            textAlign: TextAlign.justify,
            //style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(height: 16),

          Text(
            'Final Steps',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          SizedBox(height: 5),
          Text(
            'Review your request to double-check all the details for accuracy. Then, submit your request, after which the driver will review it and accept if available. '
            'Once accepted, you can discuss terms, conditions, and payment directly with the driver.',
            textAlign: TextAlign.justify,
           
          ),
          SizedBox(height: 16),

          Text(
            'Note: The payment process for Service Rides is handled directly between you and the driver.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
