import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:passenger/models/direction_details.dart'; // Import Firestore

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
      backgroundColor: Colors.black54,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FutureBuilder<double>(
          future: getFareAmount(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // Show a loading indicator while fetching data
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}")); // Show an error message if there is an error
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
                      "This is fare amount ( ₱ ${fare.toStringAsFixed(2)} ) to be charged from the passenger.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey
                      ),
                    ),
                  ),
                  const SizedBox(height: 31,),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, "paid");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "PAY CASH",
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
