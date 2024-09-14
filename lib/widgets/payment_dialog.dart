import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:passenger/global/global_var.dart'; // Import global variables
import 'package:passenger/models/direction_details.dart';
import 'package:passenger/pages/rating_page.dart';
import 'package:passenger/widgets/rating_dialog.dart'; // Import Firestore

class PaymentDialog extends StatefulWidget {
  final DirectionDetails? directionDetails;
  final String fareAmount;

  PaymentDialog({Key? key, this.directionDetails, required this.fareAmount})
      : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  int selectedStarCount = 0;
  Map? tripDetails;

  @override
  void initState() {
    super.initState();
    fetchTripDetails();
  }

void fetchTripDetails() async {
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  
  DatabaseReference completedTripsRef = FirebaseDatabase.instance.ref().child("tripRequests");
  DatabaseEvent event = await completedTripsRef.orderByChild('userID').equalTo(currentUserUid).once();
  
  Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
  List<Map> tripsList = [];
  
  data.forEach((key, value) {
    tripsList.add({"key": key, ...value});
  });
  
  // Log the trip details
  if (tripsList.isNotEmpty) {
    setState(() {
      tripDetails = tripsList.last;
      print("Trip Details: $tripDetails");  // Debug print
      print("Raw Trip Ended Time: ${tripDetails!["tripEndedTime"]}"); // Debug print
    });
  }

   print("Formatted Trip Ended Time: ${formatDateTime(tripDetails?["tripEndedTime"])}");
}



  /// FARE AMOUNT FROM FIRESTORE
  Future<double> getFareAmount() async {
    try {
      return await FirebaseFirestore.instance
          .runTransaction<double>((transaction) async {
        DocumentSnapshot fareDoc = await transaction.get(FirebaseFirestore
            .instance
            .collection('currentFare')
            .doc('latestFare'));

        if (fareDoc.exists) {
          double fareAmount = (fareDoc['amount'] as num).toDouble();
          return fareAmount;
        } else {
          print("No data found at 'currentFare/latestFare'");
          return 0.0;
        }
      });
    } catch (e) {
      print("Error fetching fare amount: $e");
      return 0.0;
    }
  }

  /// PRINT FARE AMOUNT FROM TRIPREQUESTS
  Future<void> printFareAmount() async {
    if (globalTripID == null || globalTripID!.isEmpty) {
      print('Global Trip ID is not set');
      return;
    }
    DatabaseReference tripRequestRef = FirebaseDatabase.instance
        .ref()
        .child('tripRequests')
        .child(globalTripID!);
    try {
      final snapshot = await tripRequestRef.get();

      if (snapshot.exists) {
        final data = snapshot.value;

        // Ensure the data is a map
        if (data is Map) {
          // Retrieve the fareAmount directly
          final fareAmount = data['fareAmount'];

          // Safely convert fareAmount to string whether it's int or string
          String formattedFareAmount;
          if (fareAmount is int || fareAmount is double) {
            formattedFareAmount = "₱ ${fareAmount.toStringAsFixed(2)}";
          } else if (fareAmount is String) {
            formattedFareAmount = "₱ $fareAmount";
          } else {
            formattedFareAmount = "₱ 0.00"; // Default if no valid fareAmount
          }

          // Print the formatted fareAmount
          print("Fare Amount FROM TRIPREQUESTS: $formattedFareAmount");
        } else {
          print("Data is not a valid map: $data");
        }
      } else {
        print("No data available for tripID: $globalTripID");
      }
    } catch (error) {
      print("Error fetching fare amount: $error");
    }
  }

@override
Widget build(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    printFareAmount(); // Call printFareAmount without parameters
    print("Trip Details: $tripDetails"); // Debug print to verify the contents of tripDetails
    print("Formatted Trip Ended Time: ${formatDateTime(tripDetails?["tripEndedTime"])}");
  });

  return Dialog(
    insetPadding: EdgeInsets.zero,
    backgroundColor: Colors.transparent,
    child: Stack(
      children: [
        // Fullscreen white background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<double>(
              future: getFareAmount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      color: Colors.black,
                      size: 50,
                      secondRingColor: Colors.black,
                      thirdRingColor: Colors.purple,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                  );
                } else {
                  double fare = snapshot.data ?? 0.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      const Text(
                        "RECEIPT",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 25),
  
                      const Divider(
                        height: 1.5,
                        color: Colors.black54,
                        thickness: 1.0,
                      ),

                      // Centered TODA Image
                      // Center(
                      //   child: Image.asset(
                      //     'assets/images/toda.png',
                      //     height: 100, // Adjust the height as needed
                      //     width: 100,  // Adjust the width as needed
                      //   ),
                      // ),
                      const SizedBox(height: 15),

                      // Trip Date Row
if (tripDetails != null) ...[
Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between start and end
    children: [
      // This text will be moved upward using Transform
      Transform.translate(
        offset: const Offset(0, -11), // Adjust the vertical offset to move the text up
        child: Text(
          'Trip Completed:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          
        ),
      ),
      
      
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(left: 45.0), // Adjust the right padding to move the text more to the right
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Aligns the text to the end (right side)
              children: [
                Text(
                  tripDetails!["tripEndedTime"] != null &&
                  tripDetails!["tripEndedTime"]!.isNotEmpty
                    ? '${formatDateTime(tripDetails!["tripEndedTime"])} - ${formatTimeOnly(tripDetails!["publishDateTime"])}'
                    : 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.end, // Aligns the text to the end (right side) within its container
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
  const SizedBox(height: 15),
],

                    const Divider(
                        height: 1.5,
                        color: Colors.black54,
                        thickness: 1.0,
                      ),
                      const SizedBox(height: 16),
                      // Flex Layout for Pick-Up, Drop-Off, and Fare Information
                      Row(
                        children: [
                          // Left Side
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pick Up Section
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset('assets/images/combine.png', height: 100, width: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pick Up',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            tripDetails!["pickUpAddress"].toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Drop Off Section
                                Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const SizedBox(width: 27),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Move "Drop Off" text upward
          Transform.translate(
            offset: const Offset(0, -25), // Adjust this value to move the text up
            child: const Text(
              'Drop Off',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          // Move the value upward relative to "Drop Off"
          Transform.translate(
            offset: const Offset(0, -25), // Adjust this value to move the text up slightly less than the previous text
            child: Text(
              tripDetails!["dropOffAddress"].toString(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),

                                const SizedBox(height: 10),

                                // Total Fare Section
                                Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOTAL FARE label
          Transform(
            transform: Matrix4.translationValues(8, -20, 0), // Adjust the vertical offset if needed
            child: const Text(
              'TOTAL FARE:',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4), // Spacing between the label and the value
          // Total Fare value
          Transform(
            transform: Matrix4.translationValues(8, -25, 0), // Adjust the vertical offset if needed
            child: Text(
              "₱" + fare.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  ],
)

                              ],
                            ),
                          ),

                          // Right Side
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundImage: tripDetails!["driverPhoto"] != null &&
                                        tripDetails!["driverPhoto"].toString().isNotEmpty
                                    ? NetworkImage(tripDetails!["driverPhoto"])
                                    : AssetImage('assets/images/avatarman.png') as ImageProvider,
                                onBackgroundImageError: (exception, stackTrace) {
                                  print("Failed to load image: $exception");
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${tripDetails!["firstName"] ?? "N/A"} ${tripDetails!["lastName"] ?? "N/A"}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'ID Number:',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${tripDetails!["idNumber"] ?? "N/A"}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Body Number:',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${tripDetails!["bodyNumber"] ?? "N/A"}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(
                        height: 1.5,
                        color: Colors.black54,
                        thickness: 1.0,
                      ),
                      const SizedBox(height: 30),

                      // Rating Section CENTER
                      const Text(
                        "How was your trip?",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              size: 45.0,
                              color: index < selectedStarCount
                                  ? Color(0xFFFBC02D)
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedStarCount = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 70),
                      SizedBox(
                        width: 300,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedStarCount > 0) {
                              DatabaseReference tripRequestRef =
                                  FirebaseDatabase.instance
                                      .ref()
                                      .child('tripRequests')
                                      .child(globalTripID!);
                              await tripRequestRef
                                  .child('ratings')
                                  .set(selectedStarCount.toString())
                                  .then((_) {
                                print('Rating updated successfully for tripID: ${globalTripID}');
                              }).catchError((error) {
                                print('Failed to update rating: $error');
                              });
                              await fetchDriverIDAndUpdateRatings(globalTripID!);
                            }
                            await FirebaseFirestore.instance
                                .collection('currentFare')
                                .doc('latestFare')
                                .set({'amount': ''});
                            print('Latest fare has been cleared.');
                            Navigator.of(context).pop("paid");
                            // if (globalTripID != null && globalTripID!.isNotEmpty) {
                            //   await Future.microtask(() =>
                            //       showRatingDialog(context, globalTripID!));
                            // } else {
                            //   print('Global Trip ID is not set');
                            // }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E3192),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            "RIDE COMPLETE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 41),
                    ],
                  );
                }
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.black,
              size: 30,
            ),
          ),
        ),
      ],
    ),
  );
}


String formatDateTime(String? dateTime) {
  if (dateTime == null || dateTime.isEmpty) return "N/A";

  print("Input dateTime: $dateTime");  // Debug print

  try {
    // Input format should match the dateTime format from Firebase
    DateFormat inputFormat = DateFormat("MMMM d, yyyy h:mm a");
    DateTime date = inputFormat.parse(dateTime);
    // Output format can be the same as input or adjusted as needed
    DateFormat outputFormat = DateFormat('MMMM d, yyyy h:mm a');
    return outputFormat.format(date);
  } catch (e) {
    print("Date parsing error: $e");
    return "Invalid date format";
  }
}




  String formatTimeOnly(String? time) {
    if (time == null) return "N/A";
    try {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      DateTime date = dateFormat.parse(time);
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return "Invalid time format";
    }
  }

  Future<void> fetchDriverIDAndUpdateRatings(String tripID) async {
    try {
      DatabaseReference tripRef =
          FirebaseDatabase.instance.ref().child('tripRequests').child(tripID);
      DatabaseEvent tripEvent = await tripRef.once();
      DataSnapshot tripSnapshot = tripEvent.snapshot;

      if (tripSnapshot.value == null) {
        print('No data found for tripID: $tripID');
        return;
      }

      Map<String, dynamic> tripData =
          Map<String, dynamic>.from(tripSnapshot.value as Map);

      if (tripData.containsKey('driverID')) {
        String driverID = tripData['driverID'];
        print('Driver ID retrieved: $driverID');
        await findAndUpdateDriverRatings(driverID, selectedStarCount);
      } else {
        print('Driver ID not found in trip data for tripID: $tripID');
      }
    } catch (e) {
      print('Error fetching driverID: $e');
    }
  }

  Future<void> findAndUpdateDriverRatings(String driverID, int rating) async {
    try {
      print('Finding UID for driverID: $driverID');
      DatabaseReference driversAccountRef =
          FirebaseDatabase.instance.ref().child('driversAccount');
      DatabaseEvent driversEvent = await driversAccountRef.once();
      DataSnapshot driversSnapshot = driversEvent.snapshot;

      if (driversSnapshot.value == null) {
        print('No data found in driversAccount');
        return;
      }

      Map<String, dynamic> driversData =
          Map<String, dynamic>.from(driversSnapshot.value as Map);
      String? uid;

      for (var key in driversData.keys) {
        if (driversData[key]['uid'] == driverID) {
          uid = key;
          break;
        }
      }

      if (uid != null) {
        print('UID found: $uid');
        await updateDriverRatings(uid, rating);
      } else {
        print('UID not found for driverID: $driverID');
      }
    } catch (e) {
      print('Error finding UID: $e');
    }
  }

  Future<void> updateDriverRatings(String uid, int rating) async {
    try {
      print('Updating ratings for UID: $uid with rating: $rating');
      DatabaseReference driverRef =
          FirebaseDatabase.instance.ref().child('driversAccount').child(uid);
      DatabaseEvent driverEvent = await driverRef.child('totalRatings').once();
      DataSnapshot driverSnapshot = driverEvent.snapshot;

      Map<String, dynamic> driverData = driverSnapshot.value != null
          ? Map<String, dynamic>.from(driverSnapshot.value as Map)
          : {};

      int currentRatingSum = driverData['ratingSum'] ?? 0;
      int ratingCount = driverData['ratingCount'] ?? 0;

      int newRatingSum = currentRatingSum + rating;
      int newRatingCount = ratingCount + 1;
      double newAverageRating = newRatingSum / newRatingCount;

      print('Current ratingSum: $currentRatingSum');
      print('Current ratingCount: $ratingCount');
      print('New ratingSum: $newRatingSum');
      print('New ratingCount: $newRatingCount');
      print('New averageRating: $newAverageRating');

      await driverRef.child('totalRatings').set({
        'ratingSum': newRatingSum,
        'ratingCount': newRatingCount,
        'averageRating': newAverageRating,
      }).then((_) {
        print('Driver ratings updated successfully for UID: $uid');
      }).catchError((error) {
        print('Failed to update driver ratings: $error');
      });
    } catch (e) {
      print('Error updating driver ratings: $e');
    }
  }
}

void showRatingDialog(BuildContext context, String tripID) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return RatingDialog(
        tripID: tripID,
      );
    },
  );
}
