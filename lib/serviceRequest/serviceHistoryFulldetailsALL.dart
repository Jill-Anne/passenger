import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceDetailPage extends StatelessWidget {
  final DocumentSnapshot service;

  const ServiceDetailPage({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract trip and driver data from the passed DocumentSnapshot
 Map<String, dynamic> trip = {
    'from': service['from'] ?? 'Unknown',
    'to': service['to'] ?? 'Unknown',
    'status': service['status'] ?? 'Unknown',
    'date': service['postedAt'], // Assuming 'postedAt' is a Timestamp
    'dateto': service['dateto'], // Assuming there's an 'end' timestamp or similar
    'time': DateFormat('h:mm a').format(service['postedAt'].toDate()),
    'phoneNumber': service['phoneNumber'] ?? 'No phone number', // Provide a default value
    'drivername': service['drivername'] ?? 'Unknown Driver',
    'driverlastName': service['driverlastName'] ?? '',
    'driverid': service['driverid'] ?? 'No ID',
    'driverbodynumber': service['driverbodynumber'] ?? 'No Body #',
  };

  DateTime date = (service['postedAt'] as Timestamp).toDate();

return Scaffold(
  appBar: AppBar(
    title: Text("Service Details"),
  ),
  body: Stack(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 10.0), // Adjust the value as needed
        child: Column(
          children: [
            _buildTripCard(date, trip, context),
            Spacer(), // This allows the card to grow
          ],
        ),
      ),
      Positioned(
        bottom: -80, // Move the image outside the card's bounds
        left: -10, // Align it to the left
        child: Padding(
          padding: const EdgeInsets.all(0), // Optional padding for spacing
          child: Image.asset(
            'assets/images/LOGO.png',
            width: 300, // Adjust size as needed
            height: 400, // Adjust size as needed
          ),
        ),
      ),
    ],
  ),
);

}

  Widget _buildTripCard(
      DateTime date, Map<String, dynamic> trip, BuildContext context) {
    final startDate = trip['date'].toDate();
    final endDate = trip['dateto'].toDate();
    final startTime = trip['time'];
    String status = trip['status'];

        return Container(
        height: 500, // Adjust this value to set the desired height

       margin: const EdgeInsets.all(10),
        child: Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${DateFormat.yMMMd().format(date)}, $startTime",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                status != 'Pending'
                    ? IconButton(
                        icon: Image.asset(
                          'assets/images/Call.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        onPressed: () async {
                          var text =
                              'tel:${trip["phoneNumber"]}'; // Correct phone number field
                          if (await canLaunch(text)) {
                            await launch(text);
                          }
                        },
                      )
                    : const SizedBox(),
              ],
            ),
            Text.rich(
              TextSpan(
                text: 'Status: ',
                style: const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '${trip['status']}',
                    style: TextStyle(
                        color:
                            status == 'Cancelled' ? Colors.red : Colors.black,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.black, thickness: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Start Date: ',
                      style: const TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${DateFormat.yMMMd().format(startDate)}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'End Date: ',
                      style: const TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${DateFormat.yMMMd().format(endDate)}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTripDetails(context, trip),
            // Display driver details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Image.asset(
                        'assets/images/toda.png',
                        width: 100,
                        height: 100,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${trip["drivername"]} ${trip["driverlastName"]}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'ID: ',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: '${trip["driverid"]}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'Body #: ',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: '${trip["driverbodynumber"]}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'Phone #: ',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: '${trip["phoneNumber"]}', // Correct field
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
         
          ],
        ),
      ),
    )
        );
  }
}

Widget _buildTripDetails(BuildContext context, Map<String, dynamic> trip) {
  return Column(
    children: [
      Row(
        children: [
          Image.asset(
            'assets/images/initial.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'PICK-UP: ',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '${trip["from"]}',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Image.asset(
            'assets/images/final.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'DROP-OFF: ',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '${trip["to"]}',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}



