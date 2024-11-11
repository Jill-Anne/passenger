import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:passenger/env/env.dart';

String pickupAddress = ""; // Global variable for pickup address

String userName = "";
String userPhone = "";
String userID = FirebaseAuth.instance.currentUser!.uid;
String googleMapKey = Env.googleMapKey;



//String userPhone = "";
//String googleMapKey = "AIzaSyCsCaE3mYv_2jSbh0pZZswbGxL0rESl0HY";
// String serverKeyFCM =
//     "key=AAAAr926jg8:APA91bFJQq3rgHMJ4jRtu4EEKox9YTEXcUnC4-FXuKmhw70TFVzDf2NwOMNhgz5Qh2dCk52nCoIPJasecck2tHDuVB74dAPVFtm3JZRjl4gQDCWOOyBY3_akPRCdsD7XaJzmwPq3nsbw";
String? globalTripID; 
const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(14.726650, 120.943440),
  zoom: 14.4746,
);
