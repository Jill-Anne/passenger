import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentUser =
      FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trips History',
          style: TextStyle(
            color: Color.fromARGB(255, 15, 27, 90),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 15, 27, 90),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: completedTripRequestsOfCurrentUser.onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {
            return const Center(
              child: Text(
                "Error Occurred.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshotData.hasData) {
            return const Center(
              child: Text(
                "No record found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips
              .forEach((key, value) => tripsList.add({"key": key, ...value}));

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length,
            itemBuilder: ((context, index) {
              if (tripsList[index]["status"] != null &&
                  tripsList[index]["status"] == "ended" &&
                  tripsList[index]["userID"] ==
                      FirebaseAuth.instance.currentUser!.uid) {

                // Initialize the formatted trip ended time
                String tripEndedTimeFormatted = "N/A";
                String timeOnly = "N/A";
if (tripsList[index]["tripEndedTime"] != null) {
  try {
    // Define a DateFormat that matches your date string format
    DateFormat dateFormat = DateFormat("MMMM d, yyyy h:mm a");
    
    // Parse the date string into a DateTime object
    DateTime tripEndedDateTime = dateFormat.parse(tripsList[index]["tripEndedTime"]);
    
    // Format the DateTime object to your desired output format
    tripEndedTimeFormatted = DateFormat('MMMM d, yyyy h:mm a').format(tripEndedDateTime);
  } catch (e) {
    // Handle parsing exceptions
    tripEndedTimeFormatted = "Invalid date format";
    print("Date parsing error: $e");
  }
}

                    // Try parsing the publish date and time
                    if (tripsList[index]["publishDateTime"] != null) {
                      try {
                        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                        DateTime publishDateTime = dateFormat.parse(tripsList[index]["publishDateTime"]);
                        timeOnly = DateFormat('h:mm a').format(publishDateTime);
                      } catch (e) {
                        timeOnly = "Invalid time format";
                        print("Time parsing error: $e");
                      }
                    }
return Card(
  color: Colors.white, // Ensure the card background is plain white
  elevation: 0, // Set elevation to 0 to remove any shadow effects
  
  shape: RoundedRectangleBorder(
    
    side: BorderSide(color: Colors.grey[800]!, width: 1), // Dark grey border
    borderRadius: BorderRadius.circular(10),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjusted padding
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trip Ended Time
        Text(
          '$tripEndedTimeFormatted - $timeOnly',
          style: const TextStyle(
            fontSize: 16, // Font size
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Grey Line Divider
        Divider(
          color: Colors.grey[800],
          thickness: 1,
        ),
        const SizedBox(height: 16), // Adjusted spacing

        // Content Row with Two Columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side (Pick Up, Drop Off, and Fare Information Sections)
            Expanded(
              flex: 3, // Adjust the flex as needed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pick Up Section
                  Padding(
                    padding: const EdgeInsets.only(left: 0), // Adjust left padding
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/initial.png', height: 20, width: 20), // Adjusted image size
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pick Up',
                                style: TextStyle(
                                  fontSize: 12, // Reduced font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    tripsList[index]["pickUpAddress"].toString(),
                                    style: const TextStyle(
                                      fontSize: 14, // Reduced font size
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12), // Adjusted spacing

                  // Drop Off Section
                  Padding(
                    padding: const EdgeInsets.only(left: 0), // Adjust left padding
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/final.png', height: 20, width: 20), // Adjusted image size
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Drop Off',
                                style: TextStyle(
                                  fontSize: 12, // Reduced font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    tripsList[index]["dropOffAddress"].toString(),
                                    style: const TextStyle(
                                      fontSize: 14, // Reduced font size
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12), // Adjusted spacing
                  
                  // Fare Amount Section
Padding(
  padding: const EdgeInsets.only(left: 3), // Adjust the padding value as needed
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start of the column
    children: [
      // Fare Amount
      Text(
        "₱ ${tripsList[index]["fareAmount"] ?? "0.00"}",
        style: const TextStyle(
          fontSize: 20, // Font size
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 4), // Adjust spacing between fare amount and label
      // Total Fare Label
      const Text(
        'Total Fare',
        style: TextStyle(
          fontSize: 12, // Font size
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    ],
  ),
),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Right side (Driver Information)
            Flexible(
              flex: 2, // Adjust the flex as needed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Add vertical space to move the image down
                  const SizedBox(height: 0), // Adjust this value to control the image position

                  // Driver Photo
                  if (tripsList[index]["driverPhoto"] != null && tripsList[index]["driverPhoto"].toString().isNotEmpty)
                    CircleAvatar(
                      radius: 36, // Adjusted image size
                      backgroundImage: NetworkImage(
                        tripsList[index]["driverPhoto"],
                      ),
                      onBackgroundImageError: (exception, stackTrace) {
                        print("Failed to load image: $exception");
                      },
                    ),
                  const SizedBox(height: 8),

                  // Driver Name
                  Text(
                    '${tripsList[index]["firstName"] ?? "N/A"} ${tripsList[index]["lastName"] ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 16, // Font size
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),


Row(
  mainAxisAlignment: MainAxisAlignment.end, // Align items to the start of the row
  children: [
    // Label
    Text(
      'ID Number:',
      style: const TextStyle(
        fontSize: 12, // Font size
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
    const SizedBox(width: 8), // Add some spacing between the label and the value
    // Value
    Text(
      '${tripsList[index]["idNumber"] ?? "N/A"}',
      style: const TextStyle(
        fontSize: 14, // Font size
        color: Colors.black87,
      ),
    ),
  ],
),

                  const SizedBox(height: 8),

                  // Body Number


                  Row(
  mainAxisAlignment: MainAxisAlignment.end, // Align items to the start of the row
  children: [
    // Label
    Text(
      'Body Number:',
      style: const TextStyle(
        fontSize: 12, // Font size
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
    const SizedBox(width: 8), // Add some spacing between the label and the value
    // Value
    Text(
      '${tripsList[index]["bodyNumber"] ?? "N/A"}',
      style: const TextStyle(
        fontSize: 14, // Font size
        color: Colors.black87,
      ),
    ),
  ],
),

                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);

       


              } else {
                return Container();
              }
            }),
          );
        },
      ),
    );
  }
}
