import 'dart:developer'; // Import for logging

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/authentication/login_screen.dart';
import 'package:passenger/firebase_options.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/methods/firebaseToken.dart';
import 'package:passenger/pages/data_retention.dart';
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

  await FirestoredeleteExpiredData();
  await deleteExpiredData();

  // Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  await dotenv.load(fileName: ".env");
  print(dotenv.env); // Just for debugging purposes, remove it in production.

  // Set up Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Fetch and log Firebase token
  await _fetchAndLogFirebaseToken();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Request permissions only after the app is open
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:
          Color.fromARGB(255, 1, 42, 123), // Set a color or transparent
      statusBarIconBrightness: Brightness.light,
    ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppInfo()),
        ChangeNotifierProvider(
            create: (context) =>
                TripData()), // Add this line for trip data management
      ],
      child: MaterialApp(
        title: 'Passenger App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor:
              Colors.white, // Set Scaffold background color
          appBarTheme: const AppBarTheme(
            backgroundColor:
                Color.fromARGB(255, 1, 42, 123), // AppBar background color
            foregroundColor: Colors.white, // AppBar text color
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor:
                  Color.fromARGB(255, 1, 42, 123), // Status bar color
              statusBarIconBrightness:
                  Brightness.light, // Status bar icon brightness
            ),
          ),
          useMaterial3: true,
          fontFamily: 'Poppins', // Set the default font to Poppins
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'Poppins'),
            displayMedium: TextStyle(fontFamily: 'Poppins'),
            displaySmall: TextStyle(fontFamily: 'Poppins'),
            headlineMedium:
                TextStyle(fontFamily: 'Poppins'), // Replaces headline4
            headlineSmall: TextStyle(fontFamily: 'Poppins'),
            titleLarge: TextStyle(fontFamily: 'Poppins'),
            titleMedium: TextStyle(fontFamily: 'Poppins'),
            titleSmall: TextStyle(fontFamily: 'Poppins'),
            bodyLarge: TextStyle(fontFamily: 'Poppins'), // Replaces bodyText1
            bodyMedium: TextStyle(fontFamily: 'Poppins'), // Replaces bodyText2
            labelLarge:
                TextStyle(fontFamily: 'Poppins'), // For buttons and labels
            bodySmall: TextStyle(fontFamily: 'Poppins'),
            labelSmall: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
        home: FirebaseAuth.instance.currentUser == null
            ? LoginScreen()
            : HomePage(), // Load HomePage if user is authenticated
      ),
    );
  }
}

Future<void> _requestPermissions() async {
  // Request location permission (When in use)
  final locationStatus = await Permission.locationWhenInUse.status;
  if (locationStatus.isDenied) {
    // Request permission if it's denied
    final result = await Permission.locationWhenInUse.request();
    if (result.isDenied) {
      // Handle permission denied, perhaps show a dialog
      debugPrint('Location permission denied.');
    }
  }

  // Request notification permission
  final notificationStatus = await Permission.notification.status;
  if (notificationStatus.isDenied) {
    // Request permission if it's denied
    final result = await Permission.notification.request();
    if (result.isDenied) {
      // Handle permission denied, perhaps show a dialog
      debugPrint('Notification permission denied.');
    }
  }
}

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  // Handle background message
  // You can show a local notification or update app state here
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
