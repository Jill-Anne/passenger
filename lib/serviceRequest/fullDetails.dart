import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Import Firestore if needed



class FullDetails extends StatelessWidget {
  final DocumentSnapshot trip;

  const FullDetails({Key? key, required this.trip}) : super(key: key);
  

  @override
  Widget build(BuildContext context) {
    final startDate = trip['date'].toDate();
    final endDate = trip['dateto'].toDate();
    final startTime = trip['time'];
    String status = trip['status'];

    
    double leftPadding = 30.0;
    double topPadding = 0;
    double rightPadding = 30.0;
    double bottomPadding = 0;


    // Generate a list of dates from startDate to endDate
    List<DateTime> dates = [];
    for (DateTime date = startDate;
        date.isBefore(endDate.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      dates.add(date);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
  itemCount: dates.length,
  itemBuilder: (context, index) {
    // Get the current date being processed
    final date = dates[index]; // This is a DateTime object

    // Check the status for this date from the Firestore structure
    String status = 'unknown'; // Default status
    if (trip['dates'] != null && trip['dates'] is List) {
      for (var dateEntry in trip['dates']) {
        // Compare the date with the entries in Firestore
        if ((dateEntry['date'] as Timestamp).toDate().isSameDay(date)) {
          status = dateEntry['status']; // Get the status from Firestore
          break; // Exit the loop once the status is found
        }
      }
    }
           
          },
        ),
      ),
    );
  }
}




Future<void> _completeRide(DocumentSnapshot trip, DateTime dateToComplete) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Reference to the specific Advance Booking document
    final bookingRef = firestore.collection('Advance Bookings').doc(trip.id);

    // Retrieve the booking data
    final bookingData = await bookingRef.get();

    if (!bookingData.exists) {
      print("No such document in Advance Bookings!");
      return;
    }

    // Get the current date and time for completion
    DateTime now = DateTime.now();
    String completedTimeFormatted = DateFormat('MMMM d, yyyy').format(now) + " at " + DateFormat('h:mm a').format(now);

    // Update the status in the booking data
    Map<String, dynamic> updatedData = bookingData.data()!;

    // Get the existing dates array
    List<dynamic> dates = updatedData['dates'];

    // Find the date to complete in the dates array
    for (var dateEntry in dates) {
      if ((dateEntry['date'] as Timestamp).toDate().isSameDay(dateToComplete)) {
        // Update the status of the specific date entry to 'Completed'
        dateEntry['status'] = 'Completed';
        
        // Add the completed time to the specific date entry
        dateEntry['completed time'] = completedTimeFormatted;
        break; // Exit the loop once the date is found
      }
    }

    // Update the booking document with the modified dates array in "Advance Bookings"
    await bookingRef.update({'dates': dates});
    print("Date completed successfully in Advance Bookings.");

    // Optionally update the completed time in the main document
   // updatedData['completed time'] = completedTimeFormatted;

    // Move the updated data to "Advance Booking History"
    //await firestore.collection('Advance Booking History').doc(trip.id).set(updatedData);
    //print("Status updated and data moved to Advance Booking History.");

  } catch (e) {
    print("Error completing ride: $e");
  }
}





Future _rejectRide(DocumentSnapshot trip, DateTime dateToReject) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Reference to the specific Advance Booking document
    final bookingRef = firestore.collection('Advance Bookings').doc(trip.id);

    // Retrieve the booking data
    final bookingData = await bookingRef.get();

    if (!bookingData.exists) {
      print("No such document in Advance Bookings!");
      return;
    }

    // Get the existing dates array
    List<dynamic> dates = bookingData.data()!['dates'];

    // Find the date to reject in the dates array
    for (var dateEntry in dates) {
      if ((dateEntry['date'] as Timestamp).toDate().isSameDay(dateToReject)) {
        // Update the status of the specific date entry to 'Cancelled'
        dateEntry['status'] = 'Cancelled';
        break; // Exit the loop once the date is found
      }
    }

    // Update the booking document with the modified dates array
    await bookingRef.update({'dates': dates});
    print("Date rejected successfully.");

    // Optionally, create a record in the Cancelled Service collection
    final cancelledRef = firestore.collection('Cancelled Service').doc(trip.id);
    await cancelledRef.set({
      ...bookingData.data()!,
      'status': 'Rejected and Cancelled', // Update overall status
      'cancelledDate': dateToReject, // Record the specific cancelled date
    });
    print("Data moved to Cancelled Service with updated status.");

  } catch (e) {
    print("Error rejecting ride: $e");
  }
}

// Extension method to check if two DateTimes are on the same day
extension DateTimeComparison on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

