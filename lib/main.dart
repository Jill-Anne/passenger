import 'dart:developer'; // Import for logging

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/authentication/login_screen.dart';
import 'package:passenger/firebase_options.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/methods/firebaseToken.dart';
import 'package:passenger/pages/home_page.dart';
import 'package:passenger/widgets/driverCancel_dialog.dart'; // Not used here but might be used elsewhere
import 'package:passenger/widgets/state_management.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Request location and notification permissions
  await _requestPermissions();

  // Set up Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Fetch and log Firebase token
  await _fetchAndLogFirebaseToken();

  runApp(MyApp());
}


Future<void> _requestPermissions() async {
  // Request location permission
  final locationStatus = await Permission.locationWhenInUse.status;
  if (locationStatus.isDenied) {
    await Permission.locationWhenInUse.request();
  }

  // Request notification permission
  final notificationStatus = await Permission.notification.status;
  if (notificationStatus.isDenied) {
    await Permission.notification.request();
  }
}

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  // You can handle background messages here
  // For example, show a local notification or update the app's state
}

// Fetch and log Firebase token
Future<void> _fetchAndLogFirebaseToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('Firebase token: $token');
      log('Firebase token: $token');
    } else {
      debugPrint('Failed to retrieve Firebase token');
      log('Failed to retrieve Firebase token');
    }
  } catch (e) {
    debugPrint('Error fetching Firebase token: $e');
    log('Error fetching Firebase token: $e');
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppInfo()),
        ChangeNotifierProvider(create: (context) => TripData()),  // Add this line for trip data management
      ],
      child: MaterialApp(
        title: 'Flutter User App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FirebaseAuth.instance.currentUser == null
            ? LoginScreen()
            : HomePage(),
             // Load HomePage if user is authenticated
      ),
    );
  }
}

