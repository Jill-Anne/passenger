import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:passenger/serviceRequest/fullDetails.dart';
import 'package:passenger/serviceRequest/service_history.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'As of $formattedDate',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(255, 1, 42, 123),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Row(
                    children: [
                      Icon(Icons.history,
                          color: Color.fromARGB(255, 1, 42, 123)),
                      SizedBox(width: 5),
                      Text(
                        'Service History',
                        style:
                            TextStyle(color: Color.fromARGB(255, 1, 42, 123)),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // Navigate to service history
             
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceHistory(),
                      ),
                    );

                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Advance Bookings')
                  .where('uid',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .where('status', isNotEqualTo: 'Deleted')
                  .orderBy('date', descending: isLatest)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.requireData;
                final DateTime now = DateTime.now();

                // Grouping the trips by their start date
                Map<DateTime, List<DocumentSnapshot>> groupedTrips = {};
                for (var doc in data.docs) {
                  DateTime startDate = doc['date'].toDate();
                  DateTime endDate = doc['dateto'].toDate();

                  // Check if the end date is in the past
                  if (endDate.isBefore(now)) {
                    // If end date has passed, update status to "No Appearance"
                    FirebaseFirestore.instance
                        .collection('Advance Bookings')
                        .doc(doc.id)
                        .update({'status': 'No Appearance'});
                    continue; // Skip showing this trip
                  }

                  // Group trips by their start date
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: Text(
                            DateFormat.yMMMd().format(groupDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 42, 123),
                            ),
                          ),
                        ),
                        // Display the ListTiles for each trip in this group
                        ...trips.map((trip) {
                          return Column(
                            children: [
                              _buildTripListTile(trip),
                              Container(
                                width: 345,
                                child: Divider(
                                    height: 1,
                                    thickness: 2,
                                    color: Colors.grey[400]),
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
