import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:passenger/serviceRequest/fullDetails.dart';


class AdvanceBooking extends StatefulWidget {
  const AdvanceBooking({Key? key}) : super(key: key);

  @override
  State<AdvanceBooking> createState() => _AdvanceBookingState();
}

class _AdvanceBookingState extends State<AdvanceBooking> {
  bool isLatest = true;

  void toggleSortOrder() {
    setState(() {
      isLatest = !isLatest;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123),
      statusBarIconBrightness: Brightness.light,
    ));

    // Get the current date
    String formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'Service Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 1, 42, 123),
      ),
      body: Column(
        children: [
          // Current date and service history display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'As of $formattedDate',
                  style: const TextStyle(
                    fontSize: 15, // Adjust font size
                    color: Color.fromARGB(255, 1, 42, 123), // Adjust font color
                    fontWeight: FontWeight.bold, // Bold font
                  ),
                ),
                // Service History button with icon
                IconButton(
                  icon: const Row(
                    children: [
                      Icon(Icons.history, color:Color.fromARGB(255, 1, 42, 123)), // Icon
                      SizedBox(width: 5), // Space between icon and text
                      Text(
                        'Service History',
                        style: TextStyle(color:Color.fromARGB(255, 1, 42, 123)), // Text color
                      ),
                    ],
                  ),
                  onPressed: () {
                    // Navigate to service history page
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const ServiceHistory(), // Replace with your ServiceHistory widget
                    //   ),
                    // );
                  },
                ),
              ],
            ),
          ),
          // StreamBuilder for listing requests
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Advance Bookings')
                  .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .where('status', isNotEqualTo: 'Deleted')
                  .orderBy('date', descending: isLatest)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.requireData;

                // Grouping the trips by their start date
                Map<DateTime, List<DocumentSnapshot>> groupedTrips = {};
                for (var doc in data.docs) {
                  DateTime startDate = doc['date'].toDate();
                  if (!groupedTrips.containsKey(startDate)) {
                    groupedTrips[startDate] = [];
                  }
                  groupedTrips[startDate]!.add(doc);
                }

                return ListView(
                  children: groupedTrips.entries.map((entry) {
                    DateTime groupDate = entry.key;
                    List<DocumentSnapshot> trips = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the group header (date)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text(
                            DateFormat.yMMMd().format(groupDate), // Format the date for display
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 42, 123),
                            ),
                          ),
                        ),
                        /// Display the ListTiles for each trip in this group
                        ...trips.map((trip) {
                          return Column(
                            children: [
                              _buildTripListTile(trip),
                               Container(
                    width: 345,
                    child: Divider(height: 1, thickness: 2, color: Colors.grey[400]),
                  ),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripListTile(DocumentSnapshot trip) {
    final startDate = trip['date'].toDate();
    final endDate = trip['dateto'].toDate();
    final startTime = trip['time'];

    return Column(
      children: [
        Container(
          color: Color.fromARGB(21, 245, 245, 245),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: Text(
              'Scheduled on ${DateFormat.yMMMd().format(startDate)} to ${DateFormat.yMMMd().format(endDate)}, $startTime',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            subtitle: Text(
              'From ${trip["from"]} to ${trip["to"]}',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            leading: Icon(Icons.event),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullDetails(trip: trip),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
