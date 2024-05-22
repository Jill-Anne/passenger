import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

String nameDriver = '';
String photoDriver = '';
String phoneNumberDriver = '';
int requestTimeoutDriver = 20;
String status = '';
String carDetailsDriver = '';
String tripStatusDisplay = 'Driver is Arriving';

  String driverPhotoUrl = "";
String firstName = "";
String lastName = "";
String idNumber = "";
String bodyNumber = "";

DateTime? selectedStartDate;
DateTime? selectedEndDate;
TimeOfDay? selectedTime;


class UserData {
  static String name = '';
  static String phone = '';
  static String email = '';

  static Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);
      DatabaseEvent event = await userRef.once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> userData = event.snapshot.value as Map<dynamic, dynamic>;
        name = userData['name'] ?? '';
        phone = userData['phone'] ?? '';
        email = userData['email'] ?? '';
      }
    }
  }
}

