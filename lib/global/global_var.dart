import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String userPhone = "";
String userID = FirebaseAuth.instance.currentUser!.uid;
//String userPhone = "";
String googleMapKey = "AIzaSyCkLt8ILMXSFRP12xS8P7830kGNBeGn47s";
// String serverKeyFCM =
//     "key=AAAAr926jg8:APA91bFJQq3rgHMJ4jRtu4EEKox9YTEXcUnC4-FXuKmhw70TFVzDf2NwOMNhgz5Qh2dCk52nCoIPJasecck2tHDuVB74dAPVFtm3JZRjl4gQDCWOOyBY3_akPRCdsD7XaJzmwPq3nsbw";

const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(14.726650, 120.943440),
  zoom: 14.4746,
);
