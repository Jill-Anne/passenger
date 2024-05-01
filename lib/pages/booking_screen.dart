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
      body: StreamBuilder(
        stream: tripRequestsRef.onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error Occurred."));
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No record found."));
          }

          Map dataTrips = snapshot.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips.forEach((key, value) {
            if (value.containsKey("tripStartDate") &&
                value.containsKey("tripEndDate") &&
                _isValidDate(value["tripStartDate"]) &&
                _isValidDate(value["tripEndDate"]) &&
                value["userID"] == FirebaseAuth.instance.currentUser?.uid &&
                value["status"] == "ended") {
              tripsList.add({"key": key, ...value});
            }
          });

          if (tripsList.isEmpty) {
            return const Center(child: Text("No completed trips found."));
          }

          return ListView.builder(
            itemCount: tripsList.length,
            itemBuilder: (context, index) {
              return _buildTripCard(tripsList[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Map trip) {
    return Card(
      color: Colors.grey[900],
      elevation: 10,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Start Date: ${trip["tripStartDate"]}",
                style: const TextStyle(color: Colors.white)),
            Text("End Date: ${trip["tripEndDate"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Pick Up Location: ${trip["pickUpAddress"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Drop Off Location: ${trip["dropOffAddress"]}",
                style: const TextStyle(color: Colors.white)),
            SizedBox(height: 10),
            Text("Driver Name: ${trip["firstName"]} ${trip["lastName"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Driver ID Number: ${trip["idNumber"]}",
                style: const TextStyle(color: Colors.white)),
            Text("Driver Body Number: ${trip["bodyNumber"]}",
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
