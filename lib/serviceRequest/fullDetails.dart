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
            return Card(
              color: Colors.white,
              elevation: 10,
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
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
                                  var text = 'tel:${trip["phoneNumber"]}';
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
                  text: '$status',
                  style: TextStyle(
                      color: status == 'Cancelled' ? Colors.red : Colors.black,
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
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text:
                                      '${DateFormat.yMMMd().format(startDate)}',
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                        children: [
                                          TextSpan(
                                            text: '${trip["from"]}',
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
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                        children: [
                                          TextSpan(
                                            text: '${trip["to"]}',
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
                            ],
                          ),
                        ),
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
                                      text: '${trip["phoneNumber"]}',
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
 Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Dialog(
                              backgroundColor: const Color(0xFF2E3192),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(leftPadding,
                                    topPadding, rightPadding, bottomPadding),
                                child: SizedBox(
                                  width: 300,
                                  height: 280,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Reject this Service?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
 

     Center(
  child: const Text(
    'Please contact the driver to discuss any concerns before rejecting the service request.',
    textAlign: TextAlign.center, // Optional: centers the text within the Text widget itself
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
      color: Colors.white70,
    ),
  ),
),


                                            
                                 
                                          const SizedBox(height: 40),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    
                                                   // reason.clear();
                                                    Navigator.pop(context);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5), // Set border radius to 5
                                                    ),
                                                    minimumSize: const Size(100, 40), 
                                                  ),
                                                  child: const Text(
                                                    'Back',
                                                    style: TextStyle(
                                                      color: Colors
                                                          .black87, // Set text color to white
                                                      fontWeight: FontWeight
                                                          .bold, 
                                                      fontSize: 16,
                                                    ),
                                                  )),
                                              const SizedBox(width: 20),
                                              ElevatedButton(
                                                  onPressed: () async {
                                                    // await FirebaseFirestore.instance
                                                    //     .collection(
                                                    //         'Advance Bookings')
                                                    //     .doc()
                                                    //     .update({
                                                    //   'status': 'Deleted',
                                                    // });
                                                    // Navigator.pop(context);
                                                    // ADD SETSTATE HERE for Confirm Booking Button

                                                    await _rejectRide(trip, date); // Pass the date directly

                                                    
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Advance Booking Rejected Successfully')),
                                                    );
                                                    setState(() {});

                                                    // Navigator.pop(context);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF922E2E),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5), // Set border radius to 5
                                                    ),
                                                    minimumSize: const Size(100, 43), 
                                                  ),
                                                  child: const Text(
                                                    'Confirm',
                                                    // 'Reject',
                                                    style: TextStyle(
                                                      color: Colors
                                                          .white, // Set text color to white
                                                      fontWeight: FontWeight
                                                          .bold, 
                                                      fontSize: 16,
                                                    ),
                                                  )),
                                            ],
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
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(5), // Set border radius to 5
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.white, // Set text color to white
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                ),
                const SizedBox(width: 10),
Visibility(
              visible: status == 'active',
              child: ElevatedButton(
                onPressed: () async {
                  await _completeRide(trip, date); // Call your completion logic

                  // Update Firestore directly here if needed
                  await FirebaseFirestore.instance
                      .collection('Advance Bookings')
                      .doc(trip.id)
                      .update({'status': 'Completed'});
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text('Complete Ride'),
              ),
            ),
              ],
            ),

                  ],
                ),
              ),
            );
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

