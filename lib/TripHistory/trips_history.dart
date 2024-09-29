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
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color:Colors.white,
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
          dataTrips.forEach((key, value) => tripsList.add({"key": key, ...value}));

    // Group trips by publish date
Map<String, List<Map>> groupedTrips = {};
for (var trip in tripsList) {
  if (trip["status"] == "ended" && trip["userID"] == FirebaseAuth.instance.currentUser!.uid) {
    // Ensure publishDateTime is available and properly formatted
    String publishDate = "Unknown Date";
    if (trip["publishDateTime"] != null) {
      try {
        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
        DateTime publishDateTime = dateFormat.parse(trip["publishDateTime"]);
        publishDate = DateFormat('MMMM d, yyyy').format(publishDateTime);
      } catch (e) {
        print("Date parsing error: $e");
      }
    }

    if (!groupedTrips.containsKey(publishDate)) {
      groupedTrips[publishDate] = [];
    }
    groupedTrips[publishDate]!.add(trip);
  }
}

// Sort the dates in descending order
List<String> sortedDates = groupedTrips.keys.toList()
  ..sort((a, b) {
    // Parse the dates back to DateTime for sorting
    DateTime dateA = DateFormat('MMMM d, yyyy').parse(a);
    DateTime dateB = DateFormat('MMMM d, yyyy').parse(b);
    return dateB.compareTo(dateA); // Descending order
  });

// Now use `sortedDates` to display trips
return ListView.builder(
  itemCount: sortedDates.length,
  itemBuilder: (context, dateIndex) {
    String dateKey = sortedDates[dateIndex];
    List<Map> tripsForDate = groupedTrips[dateKey]!;

    return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      dateKey,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 15, 27, 90),
                      ),
                    ),
                  ),
                  ...tripsForDate.map((trip) {
                    String tripEndedTimeFormatted = "N/A";
                    if (trip["tripEndedTime"] != null && trip["tripEndedTime"].toString().isNotEmpty) {
                      try {
                        DateTime? tripEndedDateTime = DateFormat("MMMM d, yyyy h:mm a").tryParse(trip["tripEndedTime"]);
                        if (tripEndedDateTime != null) {
                          tripEndedTimeFormatted = DateFormat('MMM d, yyyy h:mm a').format(tripEndedDateTime);
                        }
                      } catch (e) {
                        print("Date parsing error: $e");
                      }
                    }

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            // Navigate to full details page with all trip info
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailsPage(trip: trip),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Image.asset(
                                'assets/images/trisikol.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                              title: Text(
                                'Trip ended at $tripEndedTimeFormatted \nFare: ₱${trip["fareAmount"]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'From ${trip["pickUpAddress"]} to ${trip["dropOffAddress"]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                               trailing: const Icon(
    Icons.arrow_forward_ios, // Icon to show on the right side
    color: Colors.grey,      // Change the color of the icon
    size: 18,                // Change the size of the icon
  ),
                            ),
                          ),
                        ),
                        Divider(
                          thickness: 2,
                          color: Colors.grey[400],
                          indent: 20,
                          endIndent: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}



class TripDetailsPage extends StatelessWidget {
  final Map trip;

  const TripDetailsPage({required this.trip});

  @override
  Widget build(BuildContext context) {
    // Initialize formatted date and time variables
    String formattedPublishDate = "Unknown";
    String timeOnly = "00:00";
    String tripEndedTimeFormatted = trip["tripEndedTime"] ?? "Unknown";

    // Parse publish date and time
    if (trip["publishDateTime"] != null) {
      try {
        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
        DateTime publishDateTime = dateFormat.parse(trip["publishDateTime"]);

        formattedPublishDate = DateFormat('MMMM d, yyyy').format(publishDateTime);
        timeOnly = DateFormat('h:mm a').format(publishDateTime);
      } catch (e) {
        print("Date parsing error: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: Stack(
        children: [
          // Main page content with card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display formatted trip times
                        Text(
                          "Started: $formattedPublishDate $timeOnly\nEnded: $tripEndedTimeFormatted",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Divider
                        Divider(
                          color: Colors.grey[800],
                          thickness: 1,
                        ),
                        const SizedBox(height: 16),

                        // Trip details section with pickup, drop-off, and driver info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side: Pickup, Drop-off, and Fare
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pick Up Information
                                  _buildAddressSection(
                                    'Pick Up',
                                    trip["pickUpAddress"].toString(),
                                    'assets/images/initial.png',
                                  ),
                                  const SizedBox(height: 12),

                                  // Drop Off Information
                                  _buildAddressSection(
                                    'Drop Off',
                                    trip["dropOffAddress"].toString(),
                                    'assets/images/final.png',
                                  ),
                                  const SizedBox(height: 12),

                                  // Fare Information
                                  _buildFareSection(trip),
                                ],
                              ),
                            ),

                            // Right side: Driver Information
                            Flexible(
                              flex: 2,
                              child: _buildDriverInfo(trip),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Positioned logo outside the card at the bottom left corner
          Positioned(
            bottom: -88, // Adjust the distance from the bottom
            left: -60, // Adjust the distance from the left side
            child: Image.asset(
              'assets/images/LOGO.png',
              width: 400, // Adjust size as needed
              height: 400, // Adjust size as needed
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the address section
  Widget _buildAddressSection(String title, String address, String iconPath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(iconPath, width: 24, height: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                address,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build the fare section
// Helper method to build the fare section
Widget _buildFareSection(Map trip) {
  return Padding(
    padding: const EdgeInsets.only(left: 10.0), // Adjust the value as needed
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "₱ ${trip["fareAmount"] ?? "0.00"}",
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Total Fare',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    ),
  );
}


  // Helper method to build the driver info section
  Widget _buildDriverInfo(Map trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      
      children: [
        const SizedBox(height: 50),
                       
                                    if (trip["driverPhoto"] != null && trip["driverPhoto"].toString().isNotEmpty)
                    CircleAvatar(
                      radius: 36, // Adjusted image size
                      backgroundImage: NetworkImage(
                        trip["driverPhoto"],
                      ),
                      onBackgroundImageError: (exception, stackTrace) {
                        print("Failed to load image: $exception");
                      },
                    ),
                    const SizedBox(height: 10),
        Text(
          ' ${trip["firstName"]} ${trip["lastName"]} ',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,),
        ),
        Text(
          'Phone: ${trip["driverPhoneNumber"]}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
         Text(
          'Body Number: ${trip["bodyNumber"]}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          'ID Number: ${trip["idNumber"]}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

