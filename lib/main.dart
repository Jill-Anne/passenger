import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/authentication/login_screen.dart';
import 'package:passenger/firebase_options.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/pages/home_page.dart';

import 'package:passenger/widgets/state_management.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });

  await Permission.notification.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.notification.request();
    }
  });
  await Firebase.initializeApp();
  await UserData.fetchUserData();
  
  runApp(MyApp());
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
        home: FirebaseAuth.instance.currentUser == null ? LoginScreen() : HomePage(),
      ),
    );
  }
}
