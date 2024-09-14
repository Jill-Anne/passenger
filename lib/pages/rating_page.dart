import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RatingPage extends StatefulWidget {
  final String tripID;

  const RatingPage({Key? key, required this.tripID}) : super(key: key);

  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int selectedStarCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/MENU.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
        title: Text('Rate your Trip', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Item 1'),
              onTap: () {
                // Handle item 1 tap
              },
            ),
            ListTile(
              title: Text('Item 2'),
              onTap: () {
                // Handle item 2 tap
              },
            ),
            // Add more items here
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                Icons.star,
                color: index < selectedStarCount ? Colors.yellow : Colors.grey,
                size: 50,
              ),
              onPressed: () {
                setState(() {
                  selectedStarCount = index + 1; // Set the rating
                });
              },
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (selectedStarCount > 0) {
            // Get a reference to the specific trip request using the tripID
            DatabaseReference tripRequestRef = FirebaseDatabase.instance.ref().child('tripRequests').child(widget.tripID);

            // Save rating directly to Firebase
            await tripRequestRef.child('ratings').set(selectedStarCount.toString()).then((_) {
              print('Rating updated successfully for tripID: ${widget.tripID}');
            }).catchError((error) {
              print('Failed to update rating: $error');
            });

            // Fetch the driverID and update total ratings
            fetchDriverIDAndUpdateRatings(widget.tripID);
          }
          Navigator.of(context).pop();
        },
        label: Text('Submit'),
        icon: Icon(Icons.check),
      ),
    );
  }

  Future<void> fetchDriverIDAndUpdateRatings(String tripID) async {
    try {
      print('Fetching driverID for tripID: $tripID');

      // Get a reference to the trip request
      DatabaseReference tripRequestRef = FirebaseDatabase.instance.ref().child('tripRequests').child(tripID);

      // Retrieve driverID from the trip request
      DatabaseEvent tripEvent = await tripRequestRef.once();
      DataSnapshot tripSnapshot = tripEvent.snapshot;

      if (tripSnapshot.value == null) {
        print('No data found for tripID: $tripID');
        return;
      }

      Map<String, dynamic> tripData = Map<String, dynamic>.from(tripSnapshot.value as Map);

      if (tripData.containsKey('driverID')) {
        String driverID = tripData['driverID'];
        print('Driver ID retrieved: $driverID');
        // Now find the UID using driverID
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

      // Get a reference to the driversAccount
      DatabaseReference driversAccountRef = FirebaseDatabase.instance.ref().child('driversAccount');

      // Retrieve all drivers and find the UID for the given driverID
      DatabaseEvent driversEvent = await driversAccountRef.once();
      DataSnapshot driversSnapshot = driversEvent.snapshot;

      if (driversSnapshot.value == null) {
        print('No data found in driversAccount');
        return;
      }

      Map<String, dynamic> driversData = Map<String, dynamic>.from(driversSnapshot.value as Map);
      String? uid;

      for (var key in driversData.keys) {
        if (driversData[key]['uid'] == driverID) {
          uid = key;
          break;
        }
      }

      if (uid != null) {
        print('UID found: $uid');
        // Update ratings in the driver's UID node
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

      // Get a reference to the driver's data
      DatabaseReference driverRef = FirebaseDatabase.instance.ref().child('driversAccount').child(uid);

      // Retrieve current total ratings
      DatabaseEvent driverEvent = await driverRef.child('totalRatings').once();
      DataSnapshot driverSnapshot = driverEvent.snapshot;

      Map<String, dynamic> driverData = driverSnapshot.value != null
          ? Map<String, dynamic>.from(driverSnapshot.value as Map)
          : {};

      int currentRatingSum = driverData['ratingSum'] ?? 0;
      int ratingCount = driverData['ratingCount'] ?? 0;

      // Calculate new values
      int newRatingSum = currentRatingSum + rating;
      int newRatingCount = ratingCount + 1;
      double newAverageRating = newRatingSum / newRatingCount;

      // Log the new values
      print('Current ratingSum: $currentRatingSum');
      print('Current ratingCount: $ratingCount');
      print('New ratingSum: $newRatingSum');
      print('New ratingCount: $newRatingCount');
      print('New averageRating: $newAverageRating');

      // Update the driver's total ratings
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
