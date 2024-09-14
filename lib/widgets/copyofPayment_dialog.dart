import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/models/direction_details.dart';
import 'package:passenger/pages/rating_page.dart';
import 'package:passenger/widgets/rating_dialog.dart'; // Import Firestore

class PaymentDialog extends StatelessWidget {
  final DirectionDetails? directionDetails;

  PaymentDialog({Key? key, this.directionDetails, required String fareAmount}) : super(key: key);

  Future<double> getFareAmount() async {
    try {
      // Define a transaction to read the fare amount
      return await FirebaseFirestore.instance.runTransaction<double>((transaction) async {
        DocumentSnapshot fareDoc = await transaction.get(
          FirebaseFirestore.instance
              .collection('currentFare')
              .doc('latestFare')
        );

        if (fareDoc.exists) {
          // Extracting the fare amount from the Firestore document
          double fareAmount = (fareDoc['amount'] as num).toDouble();
          return fareAmount;
        } else {
          print("No data found at 'currentFare/latestFare'");
          return 0.0; // Return default value if no data is found
        }
      });
    } catch (e) {
      print("Error fetching fare amount: $e");
      return 0.0; // Return default value or handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(5.0),
         width: 100, // Ensure the dialog is the same width
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FutureBuilder<double>(
          future: getFareAmount(),
          builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Loading state
                  return Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      color: Colors.white,
                      size: 50, // Adjusted size to fit within the dialog
                      secondRingColor: Colors.black,
                      thirdRingColor: Colors.purple,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                  );// Show an error message if there is an error
            } else {
              double fare = snapshot.data ?? 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 21,),
                  const Text(
                    "COLLECT CASH",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 21,),
                  const Divider(
                    height: 1.5,
                    color: Colors.white70,
                    thickness: 1.0,
                  ),
                  const SizedBox(height: 16,),
                  Text(
                    "₱" + fare.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "This is fare amount  ₱ ${fare.toStringAsFixed(2)} to be charged from the passenger.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey
                      ),
                    ),
                  ),
                  const SizedBox(height: 31,),
SizedBox(
  width: 150,  // Set button width
  height: 50,  // Set button height
child: ElevatedButton(
  onPressed: () async {
    // Clear the latest fare amount from Firestore
    await FirebaseFirestore.instance
        .collection('currentFare')
        .doc('latestFare')
        .set({'amount': ''}); // Set the amount to 0 or empty
    print('Latest fare has been cleared.');

    Navigator.of(context).pop("paid");

 
    // Ensure globalTripID is set
    if (globalTripID!.isNotEmpty) {
      // Close the payment dialog and wait for it to be fully closed
      Navigator.of(context).pop("paid");
      
      // Show the rating dialog after the payment dialog is dismissed
      // Using a future to delay until the pop operation is complete
      await Future.microtask(() => showRatingDialog(context, globalTripID!));
    } else {
      print('Global Trip ID is not set');
    }
  
// Navigator.push(
//   context,
//   MaterialPageRoute(builder: (context) => RatingPage(tripID: globalTripID!)),
// );

       
    },
    style: ElevatedButton.styleFrom(
      backgroundColor:  const Color(0xFF2E3192),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5), // Border radius here
      ),
    ),
    child: const Text(
      "PAY CASH",
      style: TextStyle(
        color: Colors.white,  // Set text color to white
        fontWeight: FontWeight.bold,  // Bold text
        fontSize: 18,  // Set font size
      ),
    ),
  ),
),
const SizedBox(height: 41,)

                ],
              );
            }
          },
        ),
      ),
    );
  }
}
