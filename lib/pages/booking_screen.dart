import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

            // Additional details as needed
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _deleteTrip(trip["key"]),
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
