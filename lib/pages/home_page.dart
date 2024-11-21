import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/authentication/login_screen.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/methods/manage_drivers_methods.dart';
import 'package:passenger/methods/push_notification_service.dart';
import 'package:passenger/models/direction_details.dart';
import 'package:passenger/serviceRequest/booking_screen.dart';
import 'package:passenger/pages/online_nearby_drivers.dart';
import 'package:passenger/pages/profile_screen.dart';
import 'package:passenger/pages/search_destination _page.dart';
import 'package:passenger/pages/service_ride_page.dart';
import 'package:passenger/TripHistory/trips_history.dart';
import 'package:passenger/services/add_advancebooking.dart';
import 'package:passenger/widgets/dialog_utils.dart';
import 'package:passenger/widgets/info_dialog.dart';
import 'package:passenger/widgets/loading_dialog.dart';
import 'package:passenger/widgets/payment_dialog.dart';
import 'package:passenger/widgets/state_management.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoOrdinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;
  Future<double>? fareAmountFuture;
  String? tripID;
  String? _profileImageUrl;
String updatedPhoneNumber = ''; // Declare it at the start of your widget state
  Marker? driverMarker;
  LatLng? driverCurrentLocationLatLng;
  static Timer? _timer;

  late DateTime _startDate;
  late DateTime _endDate;
  TimeOfDay? _selectedTime;

  void makeDriverNearbyCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: const Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
              configuration, "assets/images/tracking.png")
          .then((iconImage) {
        setState(() {
          carIconNearbyDriver = iconImage;
        });
        debugPrint("Icon loaded: $carIconNearbyDriver");
      });
    } else {
      debugPrint("Icon already loaded: $carIconNearbyDriver");
    }
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child("users").child(user.uid);
      DatabaseEvent event = await userRef.once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> userData =
            event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _profileImageUrl = userData['profileImageUrl'];
          print("Profile Image URL: $_profileImageUrl"); // Debugging output
        });
      } else {
        print("No user data found"); // Debugging output
      }
    } else {
      print("No current user"); // Debugging output
    }
  }

  void updateMapTheme(GoogleMapController controller) {
// Function to update the map theme
    getJsonFileFromThemes("themes/standard_style.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

// Function to get JSON file containing map theme
  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

// Function to set Google Map style
  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

// Function to get current live location of user
  getCurrentLiveLocationOfUser() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
        currentPositionOfUser!, context);
    await getUserInfoAndCheckBlockStatus();
    // await initializeGeoFireListener();

    await initializeGeoFireListener();
  }

// Function to get user info and check block status
  getUserInfoAndCheckBlockStatus() async {
    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);

    await usersRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
          });
        } else {
          FirebaseAuth.instance.signOut();

          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));

          cMethods.displaySnackBar(
              "you are blocked. Contact admin: admin@gmail.com", context);
        }
      } else {
        FirebaseAuth.instance.signOut();
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => LoginScreen()));
      }
    });
  }

  displayUserRideDetailsContainer() async {
    ///Directions API
    await retrieveDirectionDetails();

    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 330;
      isDrawerOpened = false;
    });
  }

retrieveDirectionDetails() async {
  var appInfo = Provider.of<AppInfo>(context, listen: false);
  var pickUpLocation = appInfo.pickUpLocation;
  var dropOffDestinationLocation = appInfo.dropOffLocation;

  // Use updated pickup coordinates or defaults if null
  var pickupGeoGraphicCoOrdinates = LatLng(
      pickUpLocation?.latitudePosition ?? 0.0, 
      pickUpLocation?.longitudePosition ?? 0.0);
  
  var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
      dropOffDestinationLocation!.latitudePosition!,
      dropOffDestinationLocation.longitudePosition!);

  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) =>
        LoadingDialog(messageText: "Getting direction..."),
  );

  try {
    // Directions API
    var detailsFromDirectionAPI = await CommonMethods.getDirectionDetailsFromAPI(
        pickupGeoGraphicCoOrdinates,
        dropOffDestinationGeoGraphicCoOrdinates);
    
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

  } catch (e) {
    // Handle any errors that occur during the API call
    print("Error retrieving direction details: $e");
    // Optionally show a dialog or message to the user
    Navigator.pop(context); // Close the loading dialog
    return; // Exit the function if there was an error
  }

  Navigator.pop(context); // Close the loading dialog after successful API call

  // Draw route from pickup to dropOffDestination
  PolylinePoints pointsPolyline = PolylinePoints();
  List<PointLatLng> latLngPointsFromPickUpToDestination =
      pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

  polylineCoOrdinates.clear();
  if (latLngPointsFromPickUpToDestination.isNotEmpty) {
    latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
      polylineCoOrdinates.add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
    });
  }

  polylineSet.clear();
  setState(() {
    Polyline polyline = Polyline(
      polylineId: const PolylineId("polylineID"),
      color: Colors.pink,
      points: polylineCoOrdinates,
      jointType: JointType.round,
      width: 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: true,
    );

    polylineSet.add(polyline);
  });

  // Fit the polyline into the map
  LatLngBounds boundsLatLng;
  if (pickupGeoGraphicCoOrdinates.latitude >
          dropOffDestinationGeoGraphicCoOrdinates.latitude &&
      pickupGeoGraphicCoOrdinates.longitude >
          dropOffDestinationGeoGraphicCoOrdinates.longitude) {
    boundsLatLng = LatLngBounds(
      southwest: dropOffDestinationGeoGraphicCoOrdinates,
      northeast: pickupGeoGraphicCoOrdinates,
    );
  } else if (pickupGeoGraphicCoOrdinates.longitude >
      dropOffDestinationGeoGraphicCoOrdinates.longitude) {
    boundsLatLng = LatLngBounds(
      southwest: LatLng(pickupGeoGraphicCoOrdinates.latitude,
          dropOffDestinationGeoGraphicCoOrdinates.longitude),
      northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
          pickupGeoGraphicCoOrdinates.longitude),
    );
  } else if (pickupGeoGraphicCoOrdinates.latitude >
      dropOffDestinationGeoGraphicCoOrdinates.latitude) {
    boundsLatLng = LatLngBounds(
      southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
          pickupGeoGraphicCoOrdinates.longitude),
      northeast: LatLng(pickupGeoGraphicCoOrdinates.latitude,
          dropOffDestinationGeoGraphicCoOrdinates.longitude),
    );
  } else {
    boundsLatLng = LatLngBounds(
      southwest: pickupGeoGraphicCoOrdinates,
      northeast: dropOffDestinationGeoGraphicCoOrdinates,
    );
  }

  controllerGoogleMap!
      .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

  // Add markers to pickup and dropOffDestination points
  Marker pickUpPointMarker = Marker(
    markerId: const MarkerId("pickUpPointMarkerID"),
    position: pickupGeoGraphicCoOrdinates,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    infoWindow: InfoWindow(
        title: pickUpLocation!.placeName, snippet: "Pickup Location"),
  );

  Marker dropOffDestinationPointMarker = Marker(
    markerId: const MarkerId("dropOffDestinationPointMarkerID"),
    position: dropOffDestinationGeoGraphicCoOrdinates,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    infoWindow: InfoWindow(
        title: dropOffDestinationLocation.placeName,
        snippet: "Destination Location"),
  );

  setState(() {
    markerSet.add(pickUpPointMarker);
    markerSet.add(dropOffDestinationPointMarker);
  });

  // Add circles to pickup and dropOffDestination points
  Circle pickUpPointCircle = Circle(
    circleId: const CircleId('pickupCircleID'),
    strokeColor: Colors.blue,
    strokeWidth: 4,
    radius: 14,
    center: pickupGeoGraphicCoOrdinates,
    fillColor: Colors.pink,
  );

  Circle dropOffDestinationPointCircle = Circle(
    circleId: const CircleId('dropOffDestinationCircleID'),
    strokeColor: Colors.blue,
    strokeWidth: 4,
    radius: 14,
    center: dropOffDestinationGeoGraphicCoOrdinates,
    fillColor: Colors.pink,
  );

  setState(() {
    circleSet.add(pickUpPointCircle);
    circleSet.add(dropOffDestinationPointCircle);
  });
}

//EXIT FROM MAP CONFIRM BOOKING
  void resetAppNow(BuildContext context) {
    // Directly set the states without calling setState
    polylineCoOrdinates.clear();
    polylineSet.clear();
    markerSet.clear();
    circleSet.clear();
    rideDetailsContainerHeight = 0;
    requestContainerHeight = 0;
    tripContainerHeight = 0;
    searchContainerHeight = 276;
    bottomMapPadding = 300;
    isDrawerOpened = true;

    // Instead of restarting the app, navigate to the initial screen or reset necessary states
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const HomePage()), // Replace with your initial screen
      (Route<dynamic> route) => false,
    );
  }

  cancelRideRequest() {
    //remove ride request from database
    tripRequestRef?.remove();

    setState(() {
      stateOfApp = "normal";
    });
  }

  displayRequestContainer() {
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });
//send ride request
    makeTripRequest();
  }

  updateAvailableNearbyOnlineDriversOnMap() {
    setState(() {
      markerSet.clear(); // Clear previous markers
    });

    Set<Marker> markersTempSet = Set<Marker>();

    // Add markers for each online driver
    for (OnlineNearbyDrivers eachOnlineNearbyDriver
        in ManageDriversMethods.nearbyOnlineDriversList) {
      LatLng driverCurrentPosition = LatLng(
          eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

      Marker driverMarker = Marker(
        markerId: MarkerId(
            "driver ID = " + eachOnlineNearbyDriver.uidDriver.toString()),
        position: driverCurrentPosition,
        icon: carIconNearbyDriver!,
      );

      markersTempSet.add(driverMarker);
    }

    // Update the map with the new set of markers
    setState(() {
      markerSet = markersTempSet;
    });
  }

  

initializeGeoFireListener() {
  Geofire.initialize("onlineDrivers");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude, 50)!
      .listen((driverEvent) {
    if (driverEvent != null) {
      var onlineDriverChild = driverEvent["callBack"];

      switch (onlineDriverChild) {
        case Geofire.onKeyEntered:
          OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
          onlineNearbyDrivers.uidDriver = driverEvent["key"];
          onlineNearbyDrivers.latDriver = driverEvent["latitude"];
          onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.nearbyOnlineDriversList
                .add(onlineNearbyDrivers);
         updateAvailableNearbyOnlineDriversOnMap();
          if (nearbyOnlineDriversKeysLoaded == true) {
              //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();
          }

          break;

        case Geofire.onKeyExited:
          // When a driver exits the area, remove them from the list
          ManageDriversMethods.removeDriverFromList(driverEvent["key"]);
          
            //update drivers on google map
          updateAvailableNearbyOnlineDriversOnMap();

          break;

        case Geofire.onKeyMoved:
          OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
          onlineNearbyDrivers.uidDriver = driverEvent["key"];
          onlineNearbyDrivers.latDriver = driverEvent["latitude"];
          onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.updateOnlineNearbyDriversLocation(
                onlineNearbyDrivers);

            //update drivers on google map
          updateAvailableNearbyOnlineDriversOnMap();

          break;

        case Geofire.onGeoQueryReady:
          nearbyOnlineDriversKeysLoaded = true;

            //update drivers on google map
          updateAvailableNearbyOnlineDriversOnMap();

          break;
      }
    }
  });

  // Start periodic update to refresh the list of online drivers
  ManageDriversMethods.startPeriodicUpdate();
}

// Fetch fare amount from Firestore
Future<double> getFareAmount() async {
  if (globalTripID == null || globalTripID!.isEmpty) {
    print('Global Trip ID is not set');
    return 0.0; // Return 0.0 if ID is not set
  }

  DatabaseReference tripRequestRef = FirebaseDatabase.instance
      .ref()
      .child('tripRequests')
      .child(globalTripID!);
  
  try {
    final snapshot = await tripRequestRef.get();

    if (snapshot.exists) {
      final data = snapshot.value;

      // Ensure the data is a map
      if (data is Map) {
        // Retrieve the fareAmount directly
        final fareAmount = data['fareAmount'];

        // Safely convert fareAmount to double if possible
        if (fareAmount is num) {
          return fareAmount.toDouble();
        } else {
          print("Fare amount is not a valid number: $fareAmount");
          return 0.0; // Return default if invalid
        }
      } else {
        print("Data is not a valid map: $data");
        return 0.0; // Return default if data structure is invalid
      }
    } else {
      print("No data available for tripID: $globalTripID");
      return 0.0; // Return default if no data found
    }
  } catch (error) {
    print("Error fetching fare amount: $error");
    return 0.0; // Return default on error
  }
}


// Function to format tripEndedTime
  String formatTripEndedTime(DateTime tripEndedTime) {
    // Create a DateFormat instance with the desired pattern
    DateFormat dateFormat = DateFormat('MMMM d, yyyy h:mm a');

    // Format the DateTime object to the desired string
    return dateFormat.format(tripEndedTime);
  }

  makeTripRequest() async {
    // Push the trip request to Firebase
    tripRequestRef =
        FirebaseDatabase.instance.ref().child("tripRequests").push();

    // Store the tripID (Firebase-generated key)
    globalTripID = tripRequestRef!.key;

    // Log trip request creation
    print('Trip request created with Trip ID: $globalTripID');

    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map<String, String> pickUpCoOrdinatesMap = {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map<String, String> dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map<String, String> driverCoOrdinates = {
      "latitude": "",
      "longitude": "",
    };

    var tripData = Provider.of<TripData>(context, listen: false);
    DateFormat dateFormat = DateFormat('MMM d, yyyy');

    Map<String, Object?> dataMap = {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),
      "ratings": "",
      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,
      "driverID": "waiting",
      "driverLocation": driverCoOrdinates,
      "driverName": "",
      // "driverphoneNumber": "",
      
      "driverPhoto": "",
      "passengerPhoto": "",
      "fareAmount": "",
      "status": "new",
      "firstName": "",
      "lastName": "",
      "idNumber": "",
      "tripEndedTime": "",
      "bodyNumber": "",
      "tripStartDate": tripData.startDate != null
          ? DateFormat('MMMM d, yyyy').format(tripData.startDate!)
          : "Not set",
      "tripEndDate": tripData.endDate != null
          ? DateFormat('MMMM d, yyyy').format(tripData.endDate!)
          : "Not set",
      "tripTime": tripData.selectedTime != null
          ? tripData.selectedTime.format(context)
          : "Not set",
    };
    // Update dataMap before pushing to Firebase
    dataMap["driverPhoto"] =
        photoDriver; // assuming photoDriver is updated in fetchDriverInfoAndUpdateMap
    dataMap["phoneNumber"] =
        phoneNumber; // assuming phoneNumber is updated in fetchDriverInfoAndUpdateMap

    // Set the initial trip request data to Firebase
    tripRequestRef!.set(dataMap).then((_) async {
      print('Trip request created successfully!');
      print('Trip ID: $globalTripID');

      // Retrieve passenger's device token after pushing the initial data
      String? deviceToken = await FirebaseMessaging.instance.getToken();

      if (deviceToken != null) {
        // Update the dataMap with the device token
        dataMap["deviceToken"] = deviceToken;

        // Update the trip request in Firebase with the new dataMap
        tripRequestRef!.update(dataMap as Map<String, Object?>).then((_) {
          print("Device token added to trip request: $deviceToken");
        }).catchError((error) {
          print('Error updating trip request with device token: $error');
        });
      } else {
        print("Error: Passenger's device token is null.");
      }
    }).catchError((error) {
      print('Error creating trip request: $error');
    });

///RETRIEVE LISTEN TO DRIVER INFO
tripStreamSubscription =
        tripRequestRef!.onValue.listen((eventSnapshot) async {
      if (eventSnapshot.snapshot.value == null) {
        print("No data available for the trip.");
        return;
      }

      Map<String, dynamic> tripData =
          Map<String, dynamic>.from(eventSnapshot.snapshot.value as Map);

      // Print trip data for debugging
      print("Trip data retrieved:");
      tripData.forEach((key, value) {
        print('$key: $value');
      });

      

      // Check if 'driverID' is present
      String? driverId = tripData["driverID"];
      if (driverId == null) {
        print('Driver ID not found in trip data.');
        return;
      }
      print('Driver ID: $driverId');
      

      // Locate the correct driver using the Firebase node key
      final DatabaseReference driverListRef =
          FirebaseDatabase.instance.ref().child('driversAccount');
      driverListRef.once().then((driversSnapshot) {
        if (driversSnapshot.snapshot.value != null) {
          Map<String, dynamic> driversData =
              Map<String, dynamic>.from(driversSnapshot.snapshot.value as Map);

          // Iterate through the driver nodes to find the correct driver by uid
          String? driverKey;
          driversData.forEach((key, driverInfo) {
            if (driverInfo["uid"] == driverId) {
              driverKey = key; // Capture the key that matches the driverID
            }
          });

          if (driverKey != null) {
            // Now that we have the correct key, fetch driver details
            DatabaseReference specificDriverRef =
                driverListRef.child(driverKey!);
            specificDriverRef.once().then((specificDriverSnapshot) {
              if (specificDriverSnapshot.snapshot.value != null) {
                Map<String, dynamic> driverData = Map<String, dynamic>.from(
                    specificDriverSnapshot.snapshot.value as Map);

                // Retrieve the driver's phone number and photo
                String phoneNumber = driverData["phoneNumber"]?.toString() ??
                    'No phone number available';
                String driverPhoto = driverData["driverPhoto"]?.toString() ??
                    'No driver photo available';

                print('Driver Phone Number: $phoneNumber');
                print('Driver Photo URL: $driverPhoto');

                // Update the trip request with driver's phone number and photo
                tripRequestRef!.update({
                  'driverPhoneNumber': phoneNumber,
                  'driverPhoto': driverPhoto,
                }).then((_) {
                  print(
                      'Driver information successfully updated in tripRequests.');
                }).catchError((error) {
                  print(
                      'Failed to update tripRequests with driver information: $error');
                });
              } else {
                print('No data found for driver with key: $driverKey');
              }
            }).catchError((error) {
              print('Error retrieving specific driver data: $error');
            });
          } else {
            print('Driver with ID $driverId not found.');
          }
        } else {
          print('No drivers data found.');
        }
      }).catchError((error) {
        print('Error retrieving drivers list: $error');
      });

  // After the update, listen again to fetch the updated phoneNumber
  tripRequestRef!.once().then((eventSnapshot) {
    if ((eventSnapshot.snapshot.value as Map)["driverPhoneNumber"] != null) {
      String updatedPhoneNumber = (eventSnapshot.snapshot.value as Map)["driverPhoneNumber"];
      print('Updated phoneNumber: $updatedPhoneNumber');
    } else {
      print('Updated phoneNumber not found in trip data.');
    }
  }).catchError((error) {
    print('Error retrieving updated trip data: $error');
  });


      if ((eventSnapshot.snapshot.value as Map)["firstName"] != null) {
        firstName = (eventSnapshot.snapshot.value as Map)["firstName"];
        print('First Name: $firstName');
      } else {
        print('First Name not found in trip data.');
      }

      if ((eventSnapshot.snapshot.value as Map)["lastName"] != null) {
        lastName = (eventSnapshot.snapshot.value as Map)["lastName"];
        print('First Name: $lastName');
      } else {
        print('First Name not found in trip data.');
      }



      if ((eventSnapshot.snapshot.value as Map)["phoneNumber"] != null) {
        phoneNumber = (eventSnapshot.snapshot.value as Map)["phoneNumber"];
        print('phoneNumber: $phoneNumber');
      } else {
        print('Phonenumber not found in trip data.');
      }
      if ((eventSnapshot.snapshot.value as Map)["idNumber"] != null) {
        idNumber = (eventSnapshot.snapshot.value as Map)["idNumber"];
      }
      if ((eventSnapshot.snapshot.value as Map)["bodyNumber"] != null) {
        bodyNumber = (eventSnapshot.snapshot.value as Map)["bodyNumber"];
      }

      if ((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null) {
        photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
      }

      if ((eventSnapshot.snapshot.value as Map)["carDetails"] != null) {
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
      }

      if ((eventSnapshot.snapshot.value as Map)["status"] != null) {
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }

      if ((eventSnapshot.snapshot.value as Map)["driverLocation"] != null) {
        double driverLatitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());
        double driverLongitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());
        LatLng driverCurrentLocationLatLng =
            LatLng(driverLatitude, driverLongitude);

        if (status == "accepted") {
          //update info for pickup to user on UI
          //info from driver current location to user pickup location
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        } else if (status == "arrived") {
          //update info for arrived - when driver reach at the pickup point of user
          setState(() {
            tripStatusDisplay = 'Driver has arrived';
          });
        } else if (status == "ontrip") {
          //update info for dropoff to user on UI
          //info from driver current location to user dropoff location
          updateFromDriverCurrentLocationToDropOffDestination(
              driverCurrentLocationLatLng);
        }
      }

      if (status == "accepted") {
        displayTripDetailsContainer();

        Geofire.stopListener();

        //remove drivers markers
        setState(() {
          markerSet.removeWhere(
              (element) => element.markerId.value.contains("driver"));
        });
      }

      if (status == "ended") {
        // Get the current time for tripEndedTime
        DateTime tripEndedDateTime = DateTime.now();

        // Format the tripEndedTime
        String formattedTripEndedTime = formatTripEndedTime(tripEndedDateTime);

        // Update tripEndedTime in Firebase immediately
        tripRequestRef!
            .update({"tripEndedTime": formattedTripEndedTime}).then((_) {
          print("Trip ended time updated: $formattedTripEndedTime");
        }).catchError((error) {
          print('Error updating trip ended time: $error');
        });

        // Fetch the fare amount from Firestore using getFareAmount method
        double fareAmount = await getFareAmount();

        if (fareAmount != 0.0) {
          // Ensure fareAmount is valid
          // Convert fareAmount to string with 2 decimal places
          String formattedFareAmount = fareAmount.toStringAsFixed(2);

          // Show the dialog and await the response
          var responseFromPaymentDialog = await showDialog(
            context: context,
            builder: (BuildContext context) =>
                PaymentDialog(fareAmount: formattedFareAmount),
          );

          if (responseFromPaymentDialog == "paid") {
            // Other actions after payment confirmation
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            // Call resetAppNow function or restart the app if needed
            resetAppNow(context);

            // Alternative for restarting the app
            // Restart.restartApp();
          }
        }
      }
    });
  }
  
/*
  void fetchDriverDetails(String driverId) async {
    print("Fetching details for driver ID: $driverId");

    if (driverId.isNotEmpty) {
      final DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child('driversAccount')
          .child(driverId);

      // Fetch driver data once
      driverRef.once().then((driverSnapshot) {
        print("Driver snapshot retrieved: ${driverSnapshot.snapshot.value}");

        if (driverSnapshot.snapshot.value != null) {
          Map<String, dynamic> driverData =
              Map<String, dynamic>.from(driverSnapshot.snapshot.value as Map);
          print('Driver data snapshot: $driverData');

          // Retrieve and update driver photo
          if (driverData.containsKey("driverPhoto")) {
            photoDriver = driverData["driverPhoto"];
            print('Driver photo URL retrieved: $photoDriver');
          } else {
            print('Driver photo URL not found in driver data.');
          }

          // Retrieve and update driver's phone number
          if (driverData.containsKey("phoneNumber")) {
            String? driverPhoneNumber = driverData["phoneNumber"];
            if (driverPhoneNumber != null && driverPhoneNumber.isNotEmpty) {
              print('Driver Phone Number retrieved: $driverPhoneNumber');
              // Update the dataMap with the driver's phone number
              tripRequestRef!
                  .update({"phoneNumber": driverPhoneNumber}).then((_) {
                print("Driver phone number updated in trip request.");
              }).catchError((error) {
                print(
                    'Error updating driver phone number in trip request: $error');
              });
            } else {
              print('Driver phone number is empty or not found.');
            }
          } else {
            print('Phone number field not found in driver data.');
          }

          // Update the dataMap with the driver photo and push to Firebase
          if (photoDriver.isNotEmpty) {
            tripRequestRef!.update({"driverPhoto": photoDriver}).then((_) {
              print("Driver photo updated in trip request.");
            }).catchError((error) {
              print('Error updating driver photo in trip request: $error');
            });
          } else {
            print('No valid driver photo URL to update in trip request.');
          }
        } else {
          print('No data found for driver.');
        }
      }).catchError((error) {
        print('Error retrieving driver data: $error');
      });
    } else {
      print('Driver ID is not available.');
    }
  }
*/

  Future<void> fetchAndPushPassengerPhoto(String userId) async {
    try {
      // Fetch user data from Firebase Realtime Database
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child("users").child(userId);
      DatabaseEvent event = await userRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> userData =
            event.snapshot.value as Map<dynamic, dynamic>;

        // Extract profileImageUrl
        String? profileImageUrl = userData['profileImageUrl'];

        // Check if profileImageUrl is available and not empty
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          // Push profileImageUrl to tripRequestRef
          tripRequestRef!.update({"passengerPhoto": profileImageUrl}).then((_) {
            print('Passenger photo URL updated successfully.');
          }).catchError((error) {
            print('Failed to update passenger photo URL: $error');
          });
        } else {
          print('No profile image URL found for user.');
        }
      } else {
        print('User data does not exist.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  displayTripDetailsContainer() {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(
      LatLng driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var userPickUpLocationLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if (directionDetailsPickup == null) {
        print("Direction details are null");
        requestingDirectionDetailsInfo = false;
        return;
      }

      print("Driver location: $driverCurrentLocationLatLng");
      setState(() {
        tripStatusDisplay =
            "Your driver is coming in ${directionDetailsPickup.durationTextString}";
        // Update the driver's marker position directly within the setState
        markerSet
            .removeWhere((marker) => marker.markerId.value == "driverMarker");
        markerSet.add(Marker(
          markerId: MarkerId("driverMarker"),
          position: driverCurrentLocationLatLng,
          icon: carIconNearbyDriver!,
        ));

        // Update camera position to focus on the driver's location
        if (controllerGoogleMap != null) {
          print("Animating camera to: $driverCurrentLocationLatLng");
          controllerGoogleMap!.animateCamera(
              CameraUpdate.newLatLng(driverCurrentLocationLatLng));
        } else {
          print("Google Map controller is null");
        }
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(
      driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).dropOffLocation;
      var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePosition!,
          dropOffLocation.longitudePosition!);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if (directionDetailsPickup == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            "Driving to drop-off location ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

/*
 noDriverAvailable() async {
    var result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text("No Driver Available"),
        content: Text(
            "No driver found in the nearby location. Try again later."),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context,
                  false); // return false to indicate user doesn't want to reset
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                  context, true); // return true to indicate user wants to reset
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );

    print("No driver available dialog result: $result");
  }

  */

  noDriverAvailable() async {
  var result = await showDialog(
    context: context,
    barrierDismissible: false, // Prevent tapping outside to close the dialog
    builder: (BuildContext context) => AlertDialog(
      title: const Text("No Driver Available", style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,  ),
      content: const Text(
        "No driver found in the nearby location. Try again later.",
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center, // Optional: Center the content text
      ),
      actions: <Widget>[
 // Action Button
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:  Color.fromARGB(255, 1, 42, 123),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: () {
                         cancelRideRequest(); // Call the cancelRideRequest 
              Navigator.pop(context,
                  true); // Close the dialog 
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
      ],
    ),
  );

  print("No driver available dialog result: $result");
}


  bool isCancellationHandled =
      false; // Flag to track if cancellation is handled

Future<void> searchDriver() async {
  print('searchDriver() called.');

  if (globalTripID == null) {
    print('Error: tripID is not set.');
    return;
  }

  print('Trip ID: $globalTripID');

  // Retrieve the status of the trip from Firebase
  DatabaseReference tripStatusRef = FirebaseDatabase.instance
      .ref()
      .child("tripRequests")
      .child(globalTripID!)
      .child("status");

  try {
    // Listen for real-time changes in trip status
    tripStatusRef.onValue.listen((dataSnapshot) async {
      final status = dataSnapshot.snapshot.value as String?;
      print('Status: $status');

      if (status == 'cancelled') {
        print('Trip cancelled notification received.');

        if (!isCancellationHandled) {
          isCancellationHandled = true; // Mark cancellation as handled

          if (context != null && mounted) {
            await _showDeclineDialog();
            print('Decline dialog dismissed.');
          } else {
            print('Context is null or widget is not mounted.');
          }
          cancelRideRequest();
          print('Cancellation AND RESET handled.');

          // Exit as no further actions are needed
          return;
        }
      }

      print('Status is not cancelled. Proceeding with driver search.');
    });
  } catch (error) {
    print('Error retrieving trip status: $error');
  }

  
  if (availableNearbyOnlineDriversList!.isEmpty) {
    print('No available drivers found.');
    bool shouldCancel = noDriverAvailable(); // Await the dialog result
    if (!shouldCancel) {
      cancelRideRequest(); // Cancel only if the user didn't want to reset
    }
    return; // Exit the function after handling no drivers
  }
///SELECTING DRIVER FRM LIST
 // var currentDriver = availableNearbyOnlineDriversList!.removeAt(0);
 // print('Driver selected: $currentDriver');

  // Fetch drivers from the onlineDrivers node
  DatabaseReference onlineDriversRef = FirebaseDatabase.instance.ref().child("onlineDrivers");

  try {
    DataSnapshot snapshot = await onlineDriversRef.get();

    if (snapshot.exists) {
      // Iterate through the online drivers and find a suitable one
      Map<dynamic, dynamic> driversMap = snapshot.value as Map<dynamic, dynamic>;

      // Search for a suitable driver that is both online and has "waiting" status
      for (var driverUid in driversMap.keys) {
        // Check if the driver has "waiting" status
        DatabaseReference driverRef = FirebaseDatabase.instance
            .ref()
            .child("driversAccount")
            .child(driverUid);

        DataSnapshot driverStatusSnapshot = await driverRef.child("newTripStatus").get();
        String driverStatus = driverStatusSnapshot.value.toString();

         if (driverStatus == "waiting" || driverStatus == "cancelled" ) {
          print("Driver $driverUid is online and available. Proceeding to send notification.");

          // Now send notification to this driver

          // Now send notification to this driver
          OnlineNearbyDrivers currentDriver = OnlineNearbyDrivers(
            uidDriver: driverUid,
            latDriver: driversMap[driverUid]['lat'],  // assuming lat is in the map
            lngDriver: driversMap[driverUid]['lng'],  // assuming lng is in the map
          );
          
          await sendNotificationToDriver(currentDriver);
          break;  // We found a suitable driver, no need to continue the search
        } else {
          print("Driver $driverUid is not available (status: $driverStatus). Skipping.");
        }
      }
    } else {
      print('No online drivers found.');
    }
  } catch (error) {
    print('Error fetching online drivers: $error');
  }
}


 Future<void> _showDeclineDialog() async {
  print('Preparing to show decline dialog.');

  if (context == null) {
    print('Error: Context is null when attempting to show dialog.');
    return Future.value();
  }

  try {
    print('Context is valid. Proceeding with showDialog.');

    if (!mounted) {
      print('Error: The widget is no longer mounted. Cannot show dialog.');
      return Future.value();
    }

    await showDialog(
  context: context!,
  barrierDismissible: false,
  builder: (BuildContext context) {
    print('Building AlertDialog for driver decline.');

    return Dialog(
      backgroundColor: Colors.transparent, // Make the dialog background transparent
      child: Stack(
        clipBehavior: Clip.none, // Allow the icon to overflow outside the dialog
        children: [
          // Main Dialog Container
          Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 1, 42, 123), // Deep Blue Background
              borderRadius: BorderRadius.circular(12.0), // Rounded corners for dialog
            ),
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Center(
                  child: Text(
                    'Trip Canceled',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Content
                const Center(
                  child: Text(
                    'Your trip request was canceled because it’s outside our service area.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // Action Button
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(1); // Return 1 to indicate 'OK' pressed
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Close Icon outside the dialog
          Positioned(
            top: -10, // Adjust to move the icon above the dialog
            right: -10, // Position it outside the right corner
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the dialog
                //cancelRideRequest(); // Call the cancelRideRequest function
              },
              child: Container(
                padding: EdgeInsets.all(6), // Padding inside the circle
                decoration: BoxDecoration(
                  color: Colors.white, // White background for the icon
                  shape: BoxShape.circle, // Make it circular
                ),
                child: Icon(
                  Icons.close,
                  color: Color.fromARGB(255, 1, 42, 123), // Deep blue icon color
                  size: 24, // Icon size
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
).then((_) {
  print('Dialog completion callback executed.');
});

print('showDialog() function call completed.');


    print('showDialog() function call completed.');
  } catch (e, stackTrace) {
    print('Exception in _showDeclineDialog: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> sendNotificationToDriver(OnlineNearbyDrivers currentDriver) async {
  print('sendNotificationToDriver called for driver UID: ${currentDriver.uidDriver}');

  if (tripRequestRef == null) {
    print('Trip request reference is null');
    return;
  }

  DatabaseReference driverRef = FirebaseDatabase.instance
      .ref()
      .child("driversAccount")
      .child(currentDriver.uidDriver.toString());

  // Check if the driver exists before proceeding
  try {
    final driverSnapshot = await driverRef.get();
    if (!driverSnapshot.exists) {
      print('Driver UID: ${currentDriver.uidDriver} does not exist.');
      return;
    }
  } catch (error) {
    print('Error fetching driver data: $error');
    return;
  }

  // Check if the driver's newTripStatus is 'waiting', 'cancelled', or 'timeout' before sending notification
  try {
    final newTripStatusSnapshot = await driverRef.child("newTripStatus").get();
    if (newTripStatusSnapshot.exists) {
      String currentStatus = newTripStatusSnapshot.value.toString();
      if (currentStatus == "cancelled" || currentStatus == "timeout" || currentStatus == "waiting") {
        print('Driver UID: ${currentDriver.uidDriver} can receive a new trip request.');
      } else {
        print('Driver UID: ${currentDriver.uidDriver} is not available (status: $currentStatus). Skipping notification.');
        return;
      }
    }
  } catch (error) {
    print('Error checking newTripStatus for driver UID: ${currentDriver.uidDriver}: $error');
    return;
  }

  // Update newTripStatus to the trip request ID (this ensures the driver is assigned to this trip)
  await driverRef.child("newTripStatus").set(tripRequestRef!.key).then((_) {
    print('newTripStatus updated for driver UID: ${currentDriver.uidDriver} with tripID: ${tripRequestRef!.key}');
  }).catchError((error) {
    print('Error updating newTripStatus for driver UID: ${currentDriver.uidDriver}: $error');
  });

  await driverRef.child("currentTripID").set(tripRequestRef!.key).then((_) {
    print('currentTripID updated for driver UID: ${currentDriver.uidDriver} with tripID: ${tripRequestRef!.key}');
  }).catchError((error) {
    print('Error updating currentTripID for driver UID: ${currentDriver.uidDriver}: $error');
  });

  // Get device token for the driver to send the notification
  DatabaseReference tokenOfCurrentDriverRef = driverRef.child("deviceToken");

  try {
    final dataSnapshot = await tokenOfCurrentDriverRef.get();

    if (dataSnapshot.exists && dataSnapshot.value != null) {
      String deviceToken = dataSnapshot.value.toString();
      print('Device token retrieved for driver UID: ${currentDriver.uidDriver}: $deviceToken');

      // Send notification to the driver
      await PushNotificationService.sendNotificationToSelectedDriver(
        deviceToken,
        context,
        tripRequestRef!.key.toString(),
      );
    } else {
      print('Device token not found for driver UID: ${currentDriver.uidDriver}');
    }
  } catch (error) {
    print('Error retrieving device token for driver UID: ${currentDriver.uidDriver}: $error');
  }

  // Start a timer for timeout and concurrently search for the next available driver
const oneTickPerSec = Duration(seconds: 1);

// Initialize the timeout duration for the "timeout" state to 15 seconds
const timeoutDuration = Duration(seconds: 15);

// Timer for countdown
var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
  requestTimeoutDriver = requestTimeoutDriver - 1;

  // If the trip is cancelled, stop the timer
  if (stateOfApp != "requesting") {
    timer.cancel();
    driverRef.child("newTripStatus").set("cancelled"); // Set status to cancelled
    driverRef.onDisconnect(); // Clean up the reference
    requestTimeoutDriver = 15;  // Reset timeout duration for future use
    return;
  }

  // If timeout is triggered (status is set to "timeout"), wait for 15 seconds
  if (requestTimeoutDriver == 0) {
    // Set the status to "timeout"
    driverRef.child("newTripStatus").set("timeout");
    driverRef.onDisconnect(); // Clean up the reference

searchDriver();
    // Wait for 15 seconds before continuing further logic
    Future.delayed(timeoutDuration, () {
      // After 15 seconds, proceed to search for the next driver
      print('Request timed out for driver UID: ${currentDriver.uidDriver}, searching for next available driver.');
       // Start searching for the next driver.

      // Reset the driver's status to "waiting" (driver becomes available for new requests)
      driverRef.child("newTripStatus").set("waiting");
      print('Driver UID: ${currentDriver.uidDriver} is now waiting for a new request.');

      // Reset timeout value for future use
      requestTimeoutDriver = 15;
    });
    return; // exit the timer to prevent any further actions
  }
});


  // Listen for changes in newTripStatus and handle "accepted" status
  driverRef.child("newTripStatus").onValue.listen((dataSnapshot) {
    var value = dataSnapshot.snapshot.value;
    if (value != null && value.toString() == "accepted") {
      timerCountDown.cancel(); // Cancel the timeout timer when trip is accepted
      driverRef.onDisconnect(); // Disconnect the reference
      requestTimeoutDriver = 20; // Reset the timeout for next usage
      print('Driver UID: ${currentDriver.uidDriver} has accepted the trip request.');
    }
  });
}



  @override
  void initState() {
    super.initState();
    // Initialize the Future to calculate fare amount
    if (tripDirectionDetailsInfo != null) {
      fareAmountFuture =
          CommonMethods().calculateFareAmount(tripDirectionDetailsInfo!);
    }

  // Pass the setState method to ManageDriversMethods
  ManageDriversMethods.setMapUpdateCallback(() {
    setState(() {
      updateAvailableNearbyOnlineDriversOnMap();
    });
  });

  ManageDriversMethods.startPeriodicUpdate();  // Start periodic updates
  }

// Build the UI of the home page
  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();
    // Get the pick-up and drop-off locations
    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    // Extract addresses from the location objects
    String pickUpAddress =
        pickUpLocation?.placeName ?? 'Unknown pick-up location';
    String dropOffAddress =
        dropOffDestinationLocation?.placeName ?? 'Unknown drop-off location';

    // Print the addresses to the console
    print("Pick-up Location: $pickUpAddress");
    print("Drop-off Location: $dropOffAddress");

    return Scaffold(
      key: sKey,
      drawer: ClipRRect(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(80)),
        child: Container(
          width: 255,
          color: Color.fromARGB(135, 233, 229, 229),
          child: Drawer(
            //backgroundColor:const Color.fromARGB(137, 237, 234, 234),
            child: ListView(
              children: [
                const Divider(
                  height: 1,
                  //   color: Color.fromARGB(255, 110, 108, 108),
                  thickness: 1,
                ),
                const SizedBox(
                  height: 20,
                ),

//header
                Container(
                  color: const Color.fromARGB(137, 237, 234, 234),
                  height: 160,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                    },
                    child: DrawerHeader(
                      decoration: const BoxDecoration(
                          //        color: const Color.fromARGB(137, 237, 234, 234),
                          ),
                     child: Row(
  children: [
    Container(
                            width:
                                60, // Slightly larger to accommodate the border
                            height:
                                60, // Slightly larger to accommodate the border
      decoration: BoxDecoration(
                              shape: BoxShape
                                  .circle, // Ensures the border is circular
        border: Border.all(
                                color: Color.fromARGB(
                                    255, 32, 2, 87), // Border color
          width: 4, // Border width
        ),
      ),
      child: ClipOval(
                              child: _profileImageUrl == null ||
                                      _profileImageUrl!.isEmpty
            ? Image.asset(
                "assets/images/avatarman.png",
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : Image.network(
                _profileImageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
      ),
    ),
    const SizedBox(width: 16),
    Expanded( // Added Expanded to ensure the text can take up available space
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
        children: [
          Text(
            userName,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 12, 12, 12),
              fontWeight: FontWeight.bold,
            ),
            //overflow: TextOverflow.ellipsis, // Adds ellipsis if the name is too long
            maxLines: 2, // Limit name to one line
          ),
                              const SizedBox(
                                height: 4,
                              ),
          const Text(
            "Profile",
            style: TextStyle(
              color: Color.fromARGB(95, 15, 15, 15),
            ),
          ),
        ],
      ),
    ),
  ],
),

                    ),
                  ),
                ),

                const Divider(
                  height: 1,
                  color: Color.fromARGB(255, 205, 198, 198),
                  thickness: 1,
                ),

                const SizedBox(
                  height: 10,
                ),

//body of drawer

                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => AdvanceBooking()));
                  },
                  child: ListTile(
                    leading: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.calendar_month,
                        color: Color.fromARGB(255, 14, 14, 14),
                      ),
                    ),
                    title: const Text(
                      "Service Ride",
                      style: TextStyle(color: Color.fromARGB(255, 12, 12, 12)),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => TripsHistoryPage()));
                  },
                  child: ListTile(
                    leading: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.history,
                        color: Color.fromARGB(255, 12, 12, 12),
                      ),
                    ),
                    title: const Text(
                      "History",
                      style: TextStyle(color: Color.fromARGB(255, 12, 12, 12)),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    FirebaseAuth.instance.signOut();

                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => LoginScreen()));
                  },
                  child: ListTile(
                    leading: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.logout,
                        color: Color.fromARGB(255, 15, 15, 15),
                      ),
                    ),
                    title: const Text(
                      "Logout",
                      style: TextStyle(color: Color.fromARGB(255, 13, 13, 13)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
//GOOGLE MAP THEMES
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);

              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                bottomMapPadding = 300;
              });

              getCurrentLiveLocationOfUser();
            },
          ),

          // Add GestureDetector and image for opening the drawer
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                sKey.currentState?.openDrawer(); // Open the drawer
              },
              child: Image.asset(
                'assets/images/MENU.png',
                width: 40,
                height: 40,
              ),
            ),
          ),

//drawer button HAMBURGER
          Positioned(
            left: 0,
            right: 0,
            bottom: -150,
            child: GestureDetector(
              onTap: () async {
                var responseFromSearchPage = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => const SearchDestinationPage()),
                );

                if (responseFromSearchPage == "placeSelected") {
                  // Once a place is selected, display user ride details container
                  displayUserRideDetailsContainer();
                }
              },
              child: Container(
                height: searchContainerHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 90, // Set desired height here
                      margin: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 1, 42, 123),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            // Icon(
                            //   Icons.search,
                            //   color: Colors.white,
                            //   size: 30,
                            // ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Where do you want to go?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Space for aesthetics, if needed
                  ],
                ),
              ),
            ),
          ),

//WHOLE BOX CONFIRMATION BOOKING IN MAP
//RIDE DETAILS CONTAINER W/ CONFIRM BOOKING
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
             //   DialogUtils.showRideOptionsDialog(context);
              },
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F3F5), // Set background color to white
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(120, 130, 91,
                          91), // Increased alpha for darker shadow
                      blurRadius: 15.0,
                      spreadRadius:
                          2.0, // Increased spreadRadius for a more noticeable shadow
                      offset: Offset(1.0,
                          1.0), // Slightly adjusted offset for better shadow effect
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/LOGO.png",
                              height: 35,
                              width: 35,
                            ),
                            const SizedBox(width: 8), // Added for spacing
                            const Text(
                              'Ride Now',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons
                                .arrow_forward), // Icon indicating that clicking will lead to another page
                          ],
                        ),
                        SizedBox(
                            height: 15), // Adjusted for spacing above the card
                        // Adjusted for spacing above the container

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/initial.png',
                                    width: 24,
                                    height: 24, // Adjust the size as needed
                                    //fit: BoxFit.cover,
                                  ),
                                  SizedBox(
                                      width: 8), // Space between image and text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "PICK-UP:",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          pickUpAddress,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          softWrap:
                                              true, // Enables wrapping of the text
                                          overflow: TextOverflow
                                              .visible, // Allows text to flow to the next line
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height:
                                      14), // Added for spacing between pick-up and drop-off
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/final.png',
                                    width: 24,
                                    height: 24, // Adjust the size as needed
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(
                                      width: 7), // Space between image and text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "DROP-OFF:",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          dropOffAddress,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          softWrap:
                                              true, // Enables wrapping of the text
                                          overflow: TextOverflow
                                              .visible, // Allows text to flow to the next line
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Distance and travel time on the right side
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        tripDirectionDetailsInfo
                                                ?.distanceTextString ??
                                            "Not available",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        tripDirectionDetailsInfo
                                                ?.durationTextString ??
                                            "Not available",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          color: Color(
                              0xFFD9D9D9), // Background color of the container
                          padding: const EdgeInsets.all(
                              14), // Padding inside the container
                          height: 55, // Fixed height for the container
                          child: FutureBuilder<double>(
                            future: tripDirectionDetailsInfo != null
                                ? cMethods.calculateFareAmount(
                                    tripDirectionDetailsInfo!)
                                : null,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  // Centering the text while calculating
                                  child: Text(
                                    "Calculating fare...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return const Center(
                                  // Centering the error message
                                  child: Text(
                                    "Error calculating fare",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasData) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                          16.0), // Adds padding on left and right
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "TOTAL FARE:",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "₱ ${snapshot.data!.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 19,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return const Center(
                                  // Centering the text for no fare data
                                  child: Text(
                                    "No fare data",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 10),
// Container for the buttons
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 35,
                              vertical:
                                  10), // Adjusted margin for better spacing
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Space between the buttons
                            children: [
// CANCEL BUTTON
                              Container(
                                width: 120, // Width for the Cancel button
                                height: 50, // Height for the Cancel button
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      5), // Rounded borders
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (c) =>
                                                HomePage())); // Close the dialog or screen
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white, // Background color
                                    side: const BorderSide(
                                        color: Color(0xFF2E3192),
                                        width: 2), // Blue border
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          3), // Rounded borders
                                    ),
                                    padding: const EdgeInsets.all(
                                        0), // Remove default padding
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Color(0xFF2E3192),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 50),
                              // CONFIRM BOOKING BUTTON
                              Container(
                                width:
                                    130, // Width for the Confirm Booking button
                                height:
                                    50, // Height for the Confirm Booking button
                                //  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjusted margin for better spacing
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      3), // Rounded borders
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Dialog(
                                          child: SizedBox(
                                            width: 250,
                                            height: 250,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'Select Service',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 18,
                                                    color: Color(0xFF2E3192),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  width: 250,
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      setState(() {
                                                        stateOfApp =
                                                            "requesting";
                                                      });

                                                      displayRequestContainer();
                                                      // get nearest available online drivers
                                                      availableNearbyOnlineDriversList =
                                                          ManageDriversMethods
                                                              .nearbyOnlineDriversList;

                                                      // search driver
                                                      searchDriver();
                                                      // ADD SETSTATE HERE for Confirm Booking Button
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10),
                                                      backgroundColor: const Color(
                                                          0xFF2E3192), // Background color of the button
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Image.asset(
                                                          'assets/images/ridenow.png',
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        const Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Ride now!', // Custom text for the booking action
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Available only at 8pm onwards', // Custom text for the booking action
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w200,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Container(
                                                  width: 250,
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (c) =>
                                                              ServiceRidePage(
                                                            name: userName,
                                                            phone: userPhone,
                                                          ),
                                                        ),
                                                      );

                                                      // _selectDateRange(context);

                                                      // ADD SETSTATE HERE for Confirm Booking Button
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10),
                                                      backgroundColor: const Color(
                                                          0xFF2E3192), // Background color of the button
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Image.asset(
                                                          'assets/images/Rectangle 1.png',
                                                          height: 25,
                                                        ),
                                                        SizedBox(width: 10),
                                                        const Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Service Ride', // Custom text for the booking action
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            Text(
                                                              'One time ride or Scheduled Ride', // Custom text for the booking action
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w200,
                                                                fontSize: 11,
                                                              ),
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
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    backgroundColor: const Color(
                                        0xFF2E3192), // Background color of the button
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          5), // Border radius here
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Confirm', // Custom text for the booking action
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )

//SizedBox(height: 100), // Add extra space for scrolling
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

//REQUEST RIDE CONTAINER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              decoration: const BoxDecoration(
                color: const Color.fromARGB(137, 255, 255, 255),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(118, 255, 255, 255),
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color.fromARGB(255, 1, 42, 123),
                                width: 2,
                              ),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(seconds: 1),
                            builder: (context, value, child) {
                              return Container(
                                width: 80 * value,
                                height: 80 * value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color.fromARGB(255, 1, 42, 123)
                                        .withOpacity(0.4),
                                    width: 3,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(0, 255, 255, 255),
                                width: 8,
                              ),
                            ),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(255, 18, 0, 88)),
                              strokeWidth: 3,
                              value: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        resetAppNow(context);
                        cancelRideRequest();
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.grey),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          ///trip details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.grey.withOpacity(0.5), // This line is fine now
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 30),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),

                      Center(
                        child: Container(
                          width: 200, // Adjust the width here
                          child: Divider(
                            height: 8,
                            thickness: 4,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),

                      // Trip status display text
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10.0), // Adjust the left padding here
                        child: Text(
                          tripStatusDisplay,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width:
                                  75, // Slightly larger to accommodate the border
                              height:
                                  75, // Slightly larger to accommodate the border
                              decoration: BoxDecoration(
                                color: Colors
                                    .white, // Background color for the container
                                shape: BoxShape
                                    .circle, // Ensures the border is circular
                                border: Border.all(
                                  color: Color.fromARGB(
                                      255, 32, 2, 87), // Border color
                                  width: 4, // Border width
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  photoDriver == ''
                                      ? "https://firebasestorage.googleapis.com/v0/b/capstone-ca5d5.firebasestorage.app/o/avatarman.png?alt=media&token=3a9dc208-1fe8-4571-af24-dbea29f4392e"
                                      : photoDriver,
                                  width: 65,
                                  height: 65,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child; // The image is loaded, return it.
                                    }
                                    return const CircularProgressIndicator(); // Show a loading indicator while the image is loading.
                                  },
                                  errorBuilder: (BuildContext context,
                                      Object error, StackTrace? stackTrace) {
                                    // Fallback to local asset if image fails to load
                                    return Image.asset(
                                      'assets/images/avatarman.png',
                                      width: 65,
                                      height: 65,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            // Additional widgets for driver name and car details

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$firstName $lastName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 1),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'ID #: ',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black87,
                                          fontWeight: FontWeight
                                              .bold, // Make the label bold
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      TextSpan(
                                        text: idNumber,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                          fontWeight: FontWeight
                                              .normal, // Keep the value normal weight
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'BODY #: ',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black87,
                                          fontWeight: FontWeight
                                              .bold, // Make the label bold
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      TextSpan(
                                        text: bodyNumber,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black54,
                                          fontWeight: FontWeight
                                              .normal, // Keep the value normal weight
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Divider(
                        height: 1,
                        color: Colors.grey,
                        thickness: 1,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      //call driver btn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              launchUrl(Uri.parse("tel://$phoneNumber"));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(25)),
                                    border: Border.all(
                                      width: 2,
                                      color: const Color(0xFF2E3192),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: Color.fromARGB(255, 21, 20, 20),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Text(
                                  "Call",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _selectedDate1;
  DateTimeRange? _selectedDateRange;
  TimeOfDay? _selectedTime1;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(Duration(days: 1)),
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDateRange != null) {
      setState(() {
        _selectedDateRange = pickedDateRange;
      });

      // Assuming you want to pick a time for the start date
      _selectTime(context).whenComplete(() {
        var pickUpLocation =
            Provider.of<AppInfo>(context, listen: false).pickUpLocation;
        var dropOffDestinationLocation =
            Provider.of<AppInfo>(context, listen: false).dropOffLocation;

        addAdvanceBooking(
            userName,
            pickUpLocation?.placeName ??
                'Unknown Pickup Location', // Fallback if null
            dropOffDestinationLocation?.placeName ??
                'Unknown Dropoff Location', // Fallback if null
            pickUpLocation?.latitudePosition ?? 0.0, // Fallback if null
            pickUpLocation?.longitudePosition ?? 0.0, // Fallback if null
            dropOffDestinationLocation?.latitudePosition ??
                0.0, // Fallback if null
            dropOffDestinationLocation?.longitudePosition ??
                0.0, // Fallback if null
            _selectedDateRange != null
                ? _selectedDateRange!.start
                : _selectedDate1!,
            _selectedTime1 != null ? _selectedTime1!.format(context) : '',
            _selectedDateRange != null
                ? _selectedDateRange!.end
                : _selectedDate1!,
            userPhone);

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));

        cMethods.displaySnackBar("Your service ride has been posted!", context);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != _selectedTime1) {
      setState(() {
        _selectedTime1 = pickedTime;
      });
    }
  }
}
