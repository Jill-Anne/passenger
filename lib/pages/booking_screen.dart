import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvanceBooking extends StatefulWidget {
  const AdvanceBooking({Key? key}) : super(key: key);

  @override
  State<AdvanceBooking> createState() => _AdvanceBookingState();
}

class _AdvanceBookingState extends State<AdvanceBooking> {
  final DatabaseReference tripRequestsRef =
      FirebaseDatabase.instance.ref().child("tripRequests");

  bool _isValidDate(String dateStr) {
    try {
      var parsedDate =
          DateFormat("yyyy-MM-dd HH:mm:ss.SSS").parseStrict(dateStr);
      return parsedDate != null;
    } catch (e) {
      return false;
    }
  }

  void _deleteTrip(String key) {
    // Delete the trip entry from Firebase
    tripRequestsRef.child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip deleted successfully')),
      );
      setState(() {}); // Refresh the list after deletion
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting trip: $error')),
      );
    });
  }

  final reason = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Booking',
            style: TextStyle(color: Color.fromARGB(255, 18, 2, 56))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 12, 1, 35)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Advance Bookings')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where('status', isNotEqualTo: 'Deleted')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            return const Center(child: Text('Error'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(
                  child: CircularProgressIndicator(
                color: Colors.black,
              )),
            );
          }

          final data = snapshot.requireData;

          return ListView.builder(
            itemCount: data.docs.length,
            itemBuilder: (context, index) {
              return _buildTripCard(data.docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(trip) {
    return Card(
      color: Colors.grey[900],
      elevation: 10,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Start Date: ${DateFormat.yMMMd().add_jm().format(trip['date'].toDate())}",
                style: const TextStyle(color: Colors.white)),
            Text(
                "End Date: ${DateFormat.yMMMd().add_jm().format(trip['date'].toDate())}",
                style: const TextStyle(color: Colors.white)),
            Text("Pick Up Location: ${trip["from"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Drop Off Location: ${trip["to"]}",
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text("Driver Name:  ${trip["drivername"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Driver ID Number: ${trip["driverid"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Driver Body Number: ${trip["driverbodynumber"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Status: ${trip["status"]}",
                style: const TextStyle(color: Colors.white)),

            // Additional details as needed
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                trip["status"] != 'Pending'
                    ? ElevatedButton(
                        onPressed: () async {
                          var text = 'tel:${trip["drivernumber"]}';
                          if (await canLaunch(text)) {
                            await launch(text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text('Call Driver'),
                      )
                    : const SizedBox(),
                const SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: const Color(0xFF2E3192),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
                              width: 300,
                              height: 300,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reject this Service?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white),
                                      ),
                                      const Text(
                                        '○ Changed plans',
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12,
                                            color: Colors.white),
                                      ),
                                      const Text(
                                        '○ Found alternative transportation',
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12,
                                            color: Colors.white),
                                      ),
                                      const Text(
                                        '○ Driver issue',
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12,
                                            color: Colors.white),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: TextField(
                                          controller: reason,
                                          decoration: const InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            labelText: 'Other',
                                            labelStyle: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 12,
                                                color: Colors.black),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        width: 125,
                                        // Adjusted margin for better spacing
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            // ADD SETSTATE HERE for Confirm Booking Button
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            backgroundColor: Colors
                                                .grey, // Use the color from your reusable widget
                                          ),
                                          child: const Text(
                                            'Back', // Custom text for the booking action
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 125,
                                        // Adjusted margin for better spacing
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('Advance Bookings')
                                                .doc()
                                                .update({
                                              'status': 'Deleted',
                                            });
                                            Navigator.pop(context);
                                            // ADD SETSTATE HERE for Confirm Booking Button
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            backgroundColor: Colors
                                                .red, // Use the color from your reusable widget
                                          ),
                                          child: const Text(
                                            'Reject', // Custom text for the booking action
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
