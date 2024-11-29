import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';


Future<void> deleteExpiredData() async {
  final databaseReference = FirebaseDatabase.instance.ref('tripRequests');
  final now = DateTime.now();
  
  // Commenting out the 15 days logic and implementing 3 years retention
  // final thresholdDate = now.subtract(Duration(days: 15)); // 15 days ago
  final thresholdDate = now.subtract(Duration(days: 365 * 3)); // 3 years ago

  // Fetch all trip requests from the database
  final snapshot = await databaseReference.get();

  if (snapshot.exists) {
    final tripRequests = snapshot.value as Map<dynamic, dynamic>;

    // Loop through all the trip requests
    tripRequests.forEach((key, value) {
      String? publishDateTime = value['publishDateTime']; // Use nullable String

      // Check if publishDateTime is null
      if (publishDateTime != null) {
        // Parse the publishDateTime string into a DateTime object
        DateTime publishDate = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").parse(publishDateTime);

        // Compare the publish date with the threshold date (3 years ago)
        if (publishDate.isBefore(thresholdDate)) {
          // This trip request is older than 3 years, delete it
          databaseReference.child(key).remove(); // Delete the trip request from Firebase
          print("Deleted trip request with ID: $key"); // This is printed when a request is deleted
        }
      } else {
        // If publishDateTime is null, handle the case accordingly
        print("No publishDateTime found for trip request with ID: $key");
      }
    });
  } else {
    print("No trip requests found.");
  }
}


Future<void> FirestoredeleteExpiredData() async {
  final now = DateTime.now();
  
  // Calculate the threshold date (3 years ago)
  final thresholdDate = now.subtract(Duration(days: 3 * 365)); // 3 years ago
  
  // Reference to the Firestore collections
  final advanceBookingsCollection = FirebaseFirestore.instance.collection('Advance Bookings');
  final advanceBookingHistoryCollection = FirebaseFirestore.instance.collection('Advance Booking History');

  // Query for Advance Bookings older than 3 years based on 'date' field
  final bookingsSnapshot = await advanceBookingsCollection
      .where('date', isLessThan: Timestamp.fromDate(thresholdDate))
      .get();

  if (bookingsSnapshot.docs.isNotEmpty) {
    // Loop through all documents that match the query (older than 3 years)
    for (var doc in bookingsSnapshot.docs) {
      // Delete the document from 'Advance Bookings' collection
      await doc.reference.delete();
      print("Deleted Advance Booking with ID: ${doc.id}"); // Print the document ID for tracking
    }
  } else {
    print("No Advance Bookings found older than 3 years.");
  }

  // Query for Advance Booking History older than 3 years based on 'date' field
  final historySnapshot = await advanceBookingHistoryCollection
      .where('date', isLessThan: Timestamp.fromDate(thresholdDate))
      .get();

  if (historySnapshot.docs.isNotEmpty) {
    // Loop through all documents that match the query (older than 3 years)
    for (var doc in historySnapshot.docs) {
      // Delete the document from 'Advance Booking History' collection
      await doc.reference.delete();
      print("Deleted Advance Booking History with ID: ${doc.id}"); // Print the document ID for tracking
    }
  } else {
    print("No Advance Booking History found older than 3 years.");
  }
}