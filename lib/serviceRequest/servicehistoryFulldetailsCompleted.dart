import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:passenger/methods/reusable_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceHistoryFullCompletedPage extends StatelessWidget {
  final DocumentSnapshot service;

  const ServiceHistoryFullCompletedPage({Key? key, required this.service})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extracting service data from the passed DocumentSnapshot
    Map<String, dynamic> serviceData = service.data() as Map<String, dynamic>;

    // Extract the completed time from the dates array
    String completedTime = '';
    if (serviceData.containsKey('dates') && serviceData['dates'] is List) {
      List<dynamic> datesArray = serviceData['dates'];

      for (var dateEntry in datesArray) {
        if (dateEntry is Map<String, dynamic> &&
            dateEntry['status'] == 'Completed') {
          completedTime =
              dateEntry['completed time'] ?? 'No completed time available';
          break; // Exit the loop after finding the completed time
        }
      }
    }

    // Creating a map with the service details
    Map<String, dynamic> serviceDetails = {
      'serviceId': serviceData['id'] ?? 'Unknown ID',
      'name': serviceData['name'] ?? 'Unknown',
      'from': serviceData['from'] ?? 'Unknown',
      'to': serviceData['to'] ?? 'Unknown',
      'completedTime': completedTime,
      'status': serviceData['status'] ?? 'Unknown',
      'postedAt': serviceData['postedAt'], // Assuming 'postedAt' is a Timestamp
      'phoneNumber':
          serviceData['phoneNumber'] ?? 'No phone number', // Default value
      'driverName': serviceData['drivername'] ?? 'Unknown Driver',
      'driverLastName': serviceData['driverlastName'] ?? '',
      'driverId': serviceData['driverid'] ?? 'No ID',
      'driverBodyNumber': serviceData['driverbodynumber'] ?? 'No Body #',
      'date': serviceData['postedAt'], // Assuming this is the posted date
      'dateto': serviceData['dateto'], // Added to ensure it is available
      'time': serviceData['time'] ??
          'Unknown time', // Ensure the time field is available
    };

    DateTime postedDate = (serviceDetails['postedAt'] as Timestamp).toDate();
    String formattedTime = DateFormat('h:mm a').format(postedDate);

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
            _buildTripCard(serviceDetails, formattedTime, context),
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

  Widget _buildTripCard(Map<String, dynamic> serviceDetails,
      String formattedTime, BuildContext context) {
    final startDate = (serviceDetails['date'] as Timestamp)
        .toDate(); // Ensure it's a Timestamp
    final endDate = (serviceDetails['dateto'] as Timestamp)
        .toDate(); // Ensure it's a Timestamp
    final startTime = serviceDetails['time'];
    String status = serviceDetails['status'];

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
                        "${DateFormat.yMMMd().format(startDate)}, $startTime",
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
                                  'tel:${serviceDetails["phoneNumber"]}'; // Correct phone number field
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
                    text: 'Completed Time: ',
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: '${serviceDetails['completedTime']}',
                        style: TextStyle(
                          color:
                              status == 'Cancelled' ? Colors.red : Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: 'Status: ',
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: '${serviceDetails['status']}',
                        style: TextStyle(
                          color:
                              status == 'Cancelled' ? Colors.red : Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
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
                              color: Colors.black54,
                              fontWeight: FontWeight.bold),
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
                              color: Colors.black54,
                              fontWeight: FontWeight.bold),
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
                const SizedBox(height: 25),
                _buildTripDetails(context, serviceDetails),

                // Display driver details
                Transform.translate(
                  offset: Offset(5,
                      -60), // Adjust the vertical offset to move it upward (e.g., -20)
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Transform.translate(
                              offset: Offset(
                                  25, 15), // Move the image upward by 20 pixels
                              child: Image.asset(
                                'assets/images/toda.png',
                                width: 100,
                                height: 100,
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${serviceDetails["driverName"]} ${serviceDetails["driverLastName"]}',
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
                                    text: '${serviceDetails["driverId"]}',
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
                                    text:
                                        '${serviceDetails["driverBodyNumber"]}',
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
                                    text:
                                        '${serviceDetails["phoneNumber"]}', // Correct field
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
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ));
  }

  Widget _buildTripDetails(
      BuildContext context, Map<String, dynamic> serviceDetails) {
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
                      text: '${serviceDetails["from"]}',
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
                      text: '${serviceDetails["to"]}',
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
}
