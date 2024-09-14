import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:passenger/authentication/login_screen.dart';
import 'package:permission_handler/permission_handler.dart';

// Define Valenzuela's boundary coordinates
Future<bool> isOutsideValenzuela(Position position) async {
  const double minLat = 14.609; // Example coordinates
  const double maxLat = 14.641;
  const double minLon = 120.978;
  const double maxLon = 121.026;

  // Check if the current position is outside the defined boundary
  return position.latitude < minLat ||
         position.latitude > maxLat ||
         position.longitude < minLon ||
         position.longitude > maxLon;
}

// Check Location and Navigate Function
Future<void> checkLocationAndNavigate(BuildContext context) async {
  // Request location permissions
  PermissionStatus locationStatus = await Permission.locationWhenInUse.status;
  if (locationStatus.isDenied) {
    locationStatus = await Permission.locationWhenInUse.request();
    if (locationStatus.isDenied) {
      // If permission is denied, show a message or take some action
      return;
    }
  }

  // Get the current position
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.best,
  );

  // Check if outside Valenzuela
  bool outside = await isOutsideValenzuela(position);

  if (outside) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LocationPage()),
    );
  } else {
    // If inside Valenzuela, proceed with the app logic (e.g., login or home)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}

// Initialization screen to check location
class InitializationScreen extends StatefulWidget {
  @override
  _InitializationScreenState createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await checkLocationAndNavigate(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show a loading spinner while checking
      ),
    );
  }
}

// Location Page Widget
class LocationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('Outside Valenzuela'),
        leading: BackButton(),
         // Add a back button here
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              children: [
                Text(
                  'Tri.Co services are unavailable in this area.',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'You can only book a ride within the Valenzuela City limits.',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 32.0),
                Image.asset(
  'assets/images/trisikol.png',
  height: 150.0,  // Set your desired height here
  width: 150.0,   // Set your desired width here
),

              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
       // color: Colors.white,
        height: 200.0,
        
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Navigate back
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Color.fromARGB(255, 32, 2, 87), backgroundColor: Colors.white,
              side: BorderSide(color: Color.fromARGB(255, 32, 2, 87), width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              minimumSize: Size(280.0, 50.0),
            ),
            child: Text(
              'Back',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

