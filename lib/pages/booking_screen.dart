import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  String selectedReason = '';

  bool _isValidDate(String dateStr) {
    try {
      var parsedDate =
          DateFormat("yyyy-MM-dd HH:mm:ss.SSS").parseStrict(dateStr);
      return parsedDate != null;
    } catch (e) {
      return false;
    }
  }

  bool isLatest = true; // To track the sort order

  // Function to toggle sorting
  void toggleSortOrder() {
    setState(() {
      isLatest = !isLatest;
      // The StreamBuilder will automatically re-query with the new sort order
    });
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
          actions: [
            IconButton(
              icon: Icon(
                isLatest ? Icons.arrow_downward : Icons.arrow_upward,
                color: Color.fromARGB(255, 18, 2, 56),
              ),
              onPressed:
                  toggleSortOrder, // Toggle sort order when icon is clicked
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Advance Bookings')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .where('status', isNotEqualTo: 'Deleted')
              .orderBy('date', descending: isLatest)
              .orderBy('status', descending: isLatest)
              .orderBy('__name__', descending: isLatest)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              print('Firestore error: ${snapshot.error}');
              if (snapshot.error is FirebaseException) {
                FirebaseException firebaseError =
                    snapshot.error as FirebaseException;
                print('Error Code: ${firebaseError.code}');
                print('Error Message: ${firebaseError.message}');
              }
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
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
        ));
  }

  Future<void> _completeRide(DocumentSnapshot trip) async {
    try {
      // Initialize Firestore
      final firestore = FirebaseFirestore.instance;

      // Reference to the Advance Booking document
      final bookingRef = firestore.collection('Advance Bookings').doc(trip.id);

      // Retrieve the booking data
      final bookingData = await bookingRef.get();
      if (!bookingData.exists) {
        print("No such document!");
        return;
      }

      // Reference to the Advance Booking History document
      final historyRef =
          firestore.collection('Advance Booking History').doc(trip.id);

      // Add the data to Advance Booking History
      await historyRef.set(bookingData.data()!);

      // Delete the document from Advance Bookings
      await bookingRef.delete();

      print("Ride completed and data moved successfully.");
    } catch (e) {
      print("Error completing ride: $e");
    }
  }

  Widget _buildTripCard(trip) {
    final startDate = trip['date'].toDate();
    final endDate = trip['dateto'].toDate();
    final startTime =
        trip['time']; // Assuming this field contains the time as a string
    String status =
        trip['status']; // Assuming status is stored in the trip document
        

    double leftPadding = 40.0;
    double topPadding = 0;
    double rightPadding = 40.0;
    double bottomPadding = 0;

    return Card(
      color: Colors.white, // Set background color to white
      elevation: 10,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: Colors.black, width: 2), // Set border color and width
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
                    "${DateFormat.yMMMd().format(startDate)},  $startTime",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                trip["status"] != 'Pending'
                    ? Transform.translate(
                        offset: const Offset(0,
                            10), // Adjust the y-offset to move the button down
                        child: IconButton(
                          icon: Image.asset(
                            'assets/images/Call.png',
                            width: 40, // Set width for the image
                            height: 40, // Set height for the image
                            fit: BoxFit
                                .contain, // Ensure the image fits within the bounds
                          ),
                          onPressed: () async {
                            var text = 'tel:${trip["phoneNumber"]}';
                            if (await canLaunch(text)) {
                              await launch(text);
                            }
                          },
                        ),
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
                    text: '${trip["status"]}',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),

            // Add a horizontal line
            Divider(color: Colors.black, thickness: 1),
            const SizedBox(height: 8),

            // Display Start Date in a single row
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

            // Display End Date in a single row
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

            // Two-column layout for passenger and driver information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -30),
                            child: Image.asset(
                              'assets/images/initial.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
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
                          Transform.translate(
                            offset: const Offset(0, 0),
                            child: Image.asset(
                              'assets/images/final.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
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
                      // Image above the driver name with upward adjustment
                      Transform.translate(
                        offset: const Offset(
                            0, -50), // Slight upward adjustment for the image
                        child: Image.asset(
                          'assets/images/toda.png',
                          width: 100, // Adjust width as needed
                          height: 100, // Adjust height as needed
                        ),
                      ),
                      // Move text up using Transform.translate
                      Transform.translate(
                        offset: const Offset(
                            0, -60), // Adjust the y-offset to move the text up
                        child: Text.rich(
                          TextSpan(
                        
                            children: [
                              TextSpan(
                                text: '${trip["drivername"]} ${trip["driverlastName"]}',
                                
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              
                            ],
                          ),
                        ),
                      ),

                      // Move ID text up using Transform.translate
                      Transform.translate(
                        offset: const Offset(
                            0, -60), // Adjust the y-offset to move the text up
                        child: Text.rich(
                          TextSpan(
                            text: 'ID: ',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${trip["driverid"]}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Move Body # text up using Transform.translate
                      Transform.translate(
                        offset: const Offset(
                            0, -60), // Adjust the y-offset to move the text up
                        child: Text.rich(
                          TextSpan(
                            text: 'Body #: ',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${trip["driverbodynumber"]}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Transform.translate(
                        offset: const Offset(
                            0, -60), // Adjust the y-offset to move the text up
                        child: Text.rich(
                          TextSpan(
                            text: 'Phone #: ',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${trip["phoneNumber"]}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
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
                                                    reason.clear();
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

                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'Advance Bookings')
                                                        .doc(trip
                                                            .id) // Use the document ID to delete the specific trip
                                                        .delete(); // Perform the deletion
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
                  visible: status == 'Accepted',
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement completion logic here
                      _completeRide(trip);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(5), // Set border radius to 5
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
  }
}
