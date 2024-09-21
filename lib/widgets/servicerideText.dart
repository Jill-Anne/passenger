import 'package:flutter/material.dart';

class ServiceRideInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• What is a Service Ride?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          SizedBox(height: 5),
          Text(
            'Flexible Booking: Book a ride for one or multiple days.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(height: 3),
          Text(
            'Advanced Scheduling: Schedule rides for specific dates and times in advance.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(height: 16),
          Text(
            '• Setting Up Your Service Ride',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            'o Select Dates - Choose your start and end dates on the calendar.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(height: 3),
          Text(
            'o Specify Times - Enter the times you need the ride each day.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
              SizedBox(height: 3),
          Text(
            'o Provide Details',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            
          ),
              SizedBox(height: 3),
          Text(
            '  - Input your pickup location.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
              SizedBox(height: 3),
          Text(
            '  - Add your destination.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
              SizedBox(height: 3),
          Text(
            '  - Note any special requirements.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 16),
          Text(
            '• Final Steps',
            style: TextStyle(fontWeight: FontWeight.bold , fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            'o Review Your Request - Double-check all details for accuracy.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
           SizedBox(height: 3),
          Text(
            'o Submit Your Request - Drivers will review your request and accept if available.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
           SizedBox(height: 3),
          Text(
            'o Communication - Once accepted, discuss terms, conditions, and payment directly with the driver.',
            textAlign: TextAlign.justify,
             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(height: 16),
          Text(
            'Note: The payment process for Service Rides is handled directly between you and the driver.',
            style: TextStyle(fontWeight: FontWeight.bold , fontSize: 16),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
