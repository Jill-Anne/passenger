import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
import 'package:passenger/pages/booking_screen.dart';
import 'package:passenger/pages/online_nearby_drivers.dart';
import 'package:passenger/pages/profile_screen.dart';
import 'package:passenger/pages/search_destination _page.dart';
import 'package:passenger/pages/trips_history.dart';
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
  

  Marker? driverMarker;
  LatLng? driverCurrentLocationLatLng;

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
      rideDetailsContainerHeight = 242;
      isDrawerOpened = false;
    });
  }

//Get details of place after selecting in list of prediction place????????
  retrieveDirectionDetails() async {
    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    var pickupGeoGraphicCoOrdinates = LatLng(
        pickUpLocation!.latitudePosition!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
        dropOffDestinationLocation!.latitudePosition!,
        dropOffDestinationLocation.longitudePosition!);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Getting direction..."),
    );

    ///Directions API
    var detailsFromDirectionAPI =
        await CommonMethods.getDirectionDetailsFromAPI(
            pickupGeoGraphicCoOrdinates,
            dropOffDestinationGeoGraphicCoOrdinates);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

    Navigator.pop(context);

    //draw route from pickup to dropOffDestination
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination =
        pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polylineCoOrdinates.clear();
    if (latLngPointsFromPickUpToDestination.isNotEmpty) {
      latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
        polylineCoOrdinates
            .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
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

    //fit the polyline into the map
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

    //add markers to pickup and dropOffDestination points
    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: pickupGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
          title: pickUpLocation.placeName, snippet: "Pickup Location"),
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

    //add circles to pickup and dropOffDestination points
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
  resetAppNow() {
    setState(() {
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
    });

    Restart.restartApp();
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
      markerSet.clear();
    });

    Set<Marker> markersTempSet = Set<Marker>();

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

            if (nearbyOnlineDriversKeysLoaded == true) {
              //update drivers on google map
              updateAvailableNearbyOnlineDriversOnMap();
            }

            break;

          case Geofire.onKeyExited:
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
  }

  makeTripRequest() {
    tripRequestRef =
        FirebaseDatabase.instance.ref().child("tripRequests").push();

    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map pickUpCoOrdinatesMap = {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverCoOrdinates = {
      "latitude": "",
      "longitude": "",
    };

    var tripData = Provider.of<TripData>(context, listen: false);
    DateFormat dateFormat = DateFormat('MMM d, yyyy');

    Map dataMap = {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),
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
      "driverPhone": "",
      "driverPhoto": "",
      "fareAmount": "",
      "status": "new",
      "firstName": "",
      "lastName": "",
      "idNumber": "",
      "bodyNumber": "",

      // Additional details from confirmation dialog
      // Additional details from confirmation dialog
      // Formatting the date for Firebase, with null checks
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
    print(
        "tripStartDate: ${tripData.startDate != null ? DateFormat('MMM d, yyyy').format(tripData.startDate!) : "Not set"}");
    print(
        "tripEndDate: ${tripData.endDate != null ? DateFormat('MMM d, yyyy').format(tripData.endDate!) : "Not set"}");
    print(
        "tripTime: ${tripData.selectedTime != null ? tripData.selectedTime.format(context) : "Not set"}");

    // Debug: Print the dataMap
    print('Data Map: $dataMap');

    tripRequestRef!.set(dataMap).then((_) {
      print('Trip request created successfully!');
    }).catchError((error) {
      print('Error creating trip request: $error');
    });

    tripStreamSubscription =
        tripRequestRef!.onValue.listen((eventSnapshot) async {
      if (eventSnapshot.snapshot.value == null) {
        return;
      }

      if ((eventSnapshot.snapshot.value as Map)["firstName"] != null) {
        firstName = (eventSnapshot.snapshot.value as Map)["firstName"];
        print('First Name: $firstName');
      } else {
        print('First Name not found in trip data.');
      }

      if ((eventSnapshot.snapshot.value as Map)["lastName"] != null) {
        lastName = (eventSnapshot.snapshot.value as Map)["lastName"];
        print('Last Name: $lastName');
      } else {
        print('Last Name not found in trip data.');
      }
      if ((eventSnapshot.snapshot.value as Map)["idNumber"] != null) {
        idNumber = (eventSnapshot.snapshot.value as Map)["idNumber"];
        print('Last Name: $idNumber');
      }
      if ((eventSnapshot.snapshot.value as Map)["bodyNumber"] != null) {
        bodyNumber = (eventSnapshot.snapshot.value as Map)["bodyNumber"];
        print('Last Name: $bodyNumber');
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
            tripStatusDisplay = 'Driver has Arrived';
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
        if ((eventSnapshot.snapshot.value as Map)["fareAmount"] != null) {
          double fareAmount = double.parse(
              (eventSnapshot.snapshot.value as Map)["fareAmount"].toString());

//if user click paid in payment_dialog.dart, it will go here
          var responseFromPaymentDialog = await showDialog(
            context: context,
            builder: (BuildContext context) =>
                PaymentDialog(fareAmount: fareAmount.toString()),
          );

          if (responseFromPaymentDialog == "paid") {
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();

//ALTERNATIVE FOR THIS GOING TO RESTART APP
            Restart.restartApp();
          }
        }
      }
    });
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
            "Driver is Coming - ${directionDetailsPickup.durationTextString}";
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
            "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  void noDriverAvailable() async {
    var result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text("No Driver Available"),
        content: Text(
            "No driver found in the nearby location. Do you want to try again?"),
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

  searchDriver() {
    if (availableNearbyOnlineDriversList!.isEmpty) {
      cancelRideRequest();
      noDriverAvailable();
      return;
    }
//  NOT SURE BUT IF DRIVER ALREADY RECEIVE RIDE REQUEST. HE WILL REMOVE IN ONLINE DRIVERS
    var currentDriver = availableNearbyOnlineDriversList!.removeAt(0);
    sendNotificationToDriver(currentDriver);
  }

  void sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    print(
        'sendNotificationToDriver called for driver UID: ${currentDriver.uidDriver}');
    if (tripRequestRef == null) {
      print('Trip request reference is null');
      return;
    }

    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("driversAccount")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key).then((_) {
      print(
          'newTripStatus updated for driver UID: ${currentDriver.uidDriver} with tripID: ${tripRequestRef!.key}');
    }).catchError((error) {
      print(
          'Error updating newTripStatus for driver UID: ${currentDriver.uidDriver}: $error');
    });

    // Get current driver device recognition token
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("driversAccount")
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    tokenOfCurrentDriverRef.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        String deviceToken = dataSnapshot.snapshot.value.toString();
        print(
            'Device token retrieved for driver UID: ${currentDriver.uidDriver}: $deviceToken');

        // Send notification
        PushNotificationService.sendNotificationToSelectedDriver(
          deviceToken,
          context,
          tripRequestRef!.key.toString(),
        );
      } else {
        print(
            'Device token not found for driver UID: ${currentDriver.uidDriver}');
        return;
      }
    }).catchError((error) {
      print(
          'Error retrieving device token for driver UID: ${currentDriver.uidDriver}: $error');
    });

    const oneTickPerSec = Duration(seconds: 1);

    var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
      requestTimeoutDriver = requestTimeoutDriver - 1;

      // When trip request is not requesting, means trip request cancelled - stop timer
      if (stateOfApp != "requesting") {
        timer.cancel();
        currentDriverRef.set("cancelled");
        currentDriverRef.onDisconnect();
        requestTimeoutDriver = 20;
        return; // Exit the timer callback function
      }

      // If 20 seconds passed - send notification to next nearest online available driver
      if (requestTimeoutDriver == 0) {
        timer.cancel();
        currentDriverRef.set("timeout");
        currentDriverRef.onDisconnect();
        requestTimeoutDriver = 20;

        // Send notification to next nearest online available driver
        searchDriver();
        return; // Exit the timer callback function
      }
    });

    // Listen for changes in newTripStatus
    currentDriverRef.onValue.listen((dataSnapshot) {
      var value = dataSnapshot.snapshot.value;
      if (value != null && value.toString() == "accepted") {
        timerCountDown.cancel(); // Cancel the timer when trip is accepted
        currentDriverRef.onDisconnect(); // Disconnect the reference
        requestTimeoutDriver = 20; // Reset request timeout
      }
    });
  }

// Build the UI of the home page
  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();

    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [
              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

//header
Container(
  color: Colors.black54,
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
        color: Colors.white10,
      ),
      child: Row(
        children: [
          Image.asset(
            "assets/images/avatarman.png",
            width: 60,
            height: 60,
          ),
          const SizedBox(
            width: 16,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                UserData.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "Profile",
                style: TextStyle(
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),


              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

              const SizedBox(
                height: 10,
              ),

//body

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
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    "Advance Booking",
                    style: TextStyle(color: Colors.grey),
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
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    "History",
                    style: TextStyle(color: Colors.grey),
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
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
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

//drawer button HAMBURGER
          Positioned(
            top: 36,
            left: 19,
            child: GestureDetector(
              onTap: () {
                if (isDrawerOpened == true) {
                  sKey.currentState!.openDrawer();
                } else {
                  resetAppNow();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          ///search location icon button
          Positioned(
            left: 0,
            right: 0,
            bottom: -80,
            child: Container(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Blue Background
                  Container(
                    width: MediaQuery.of(context).size.width *
                        0.85, // 95% of screen width
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3192), // Blue background color
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // White Container
                          Container(
                            width: MediaQuery.of(context).size.width *
                                0.8, // 85% of screen width
                            decoration: BoxDecoration(
                              color: Colors.white, // White background color
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded corners
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                var responseFromSearchPage =
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (c) =>
                                                SearchDestinationPage()));

                                if (responseFromSearchPage == "placeSelected") {
                                  // Once a place is selected, display user ride details container
                                  displayUserRideDetailsContainer();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .transparent, // Transparent background
                                elevation: 0, // No shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded corners
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Search Icon
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.search, // Search icon
                                      color: Colors.grey, // Grey color
                                      size: 25,
                                    ),
                                  ),
                                  // Hint Text
                                  Text(
                                    'Where do you want to go', // Hint text
                                    style: TextStyle(
                                      color: Colors.grey, // Grey color
                                      fontSize:
                                          16, // Adjust font size as needed
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                DialogUtils.showRideOptionsDialog(context);
              },
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white, // Set background color to white
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(31, 130, 91, 91),
                      blurRadius: 15.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
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
                        SizedBox(height: 0), // Added for spacing
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            elevation: 10,
                            child: Container(
                              width: MediaQuery.of(context).size.width *
                                  0.90, // Adjusted width for better visibility
                              color: Colors
                                  .white, // Adjusted for consistency with background
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    16), // Increased padding for better layout
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Total Distance:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          tripDirectionDetailsInfo
                                                  ?.distanceTextString ??
                                              "",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8), // Added for spacing
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Estimated Travel Time:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          tripDirectionDetailsInfo
                                                  ?.durationTextString ??
                                              "",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8), // Added for spacing
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Total Fare:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          tripDirectionDetailsInfo != null
                                              ? "\PHP ${cMethods.calculateFareAmount(tripDirectionDetailsInfo!).toString()}"
                                              : "",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
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

// CONFIRM BOOKING BUTTON
                        Row(
                          children: [
                            Container(
                              width: 170,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical:
                                      10), // Adjusted margin for better spacing
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  // ADD SETSTATE HERE for Confirm Booking Button
                                  setState(() {
                                    stateOfApp = "requesting";
                                  });

                                  displayRequestContainer();
                                  // get nearest avalable online drivers
                                  availableNearbyOnlineDriversList =
                                      ManageDriversMethods
                                          .nearbyOnlineDriversList;

                                  //search driver
                                  searchDriver();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: const Color(
                                      0xFF2E3192), // Use the color from your reusable widget
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Confirm Booking', // Custom text for the booking action
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
                            Container(
                              width: 170,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical:
                                      10), // Adjusted margin for better spacing
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _selectDate(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: const Color(
                                      0xFF2E3192), // Use the color from your reusable widget
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'Advance Booking', // Custom text for the booking action
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
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
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
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: 200,
                      child: LoadingAnimationWidget.flickr(
                        leftDotColor: Colors.greenAccent,
                        rightDotColor: Colors.pinkAccent,
                        size: 50,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        resetAppNow();
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
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                // Wrap with SingleChildScrollView
                padding: EdgeInsets.only(bottom: 70), // Adjust bottom padding
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      //trip status display text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tripStatusDisplay,
                            style: const TextStyle(
                              fontSize: 19,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 19,
                      ),
                      const Divider(
                        height: 1,
                        color: Colors.white70,
                        thickness: 1,
                      ),
                      const SizedBox(
                        height: 19,
                      ),
                      //image - driver name and driver car details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: Image.network(
                              photoDriver == ''
                                  ? "https://firebasestorage.googleapis.com/v0/b/flutter-uber-clone-with-admin.appspot.com/o/avatarman.png?alt=media&token=7a04943c-a566-45d3-b820-d33da3b105c7"
                                  : photoDriver,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                lastName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                idNumber,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                bodyNumber,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 19,
                      ),
                      const Divider(
                        height: 1,
                        color: Colors.white70,
                        thickness: 1,
                      ),
                      const SizedBox(
                        height: 19,
                      ),
                      //call driver btn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              launchUrl(Uri.parse("tel://$phoneNumberDriver"));
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
                                      width: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(
                                  height: 11,
                                ),
                                const Text(
                                  "Call",
                                  style: TextStyle(
                                    color: Colors.grey,
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
  TimeOfDay? _selectedTime1;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate1) {
      setState(() {
        _selectedDate1 = pickedDate;
      });
      _selectTime(context).whenComplete(() {
        var pickUpLocation =
            Provider.of<AppInfo>(context, listen: false).pickUpLocation;
        var dropOffDestinationLocation =
            Provider.of<AppInfo>(context, listen: false).dropOffLocation;
        addAdvanceBooking(
            userName,
            pickUpLocation!.placeName,
            dropOffDestinationLocation!.placeName,
            pickUpLocation!.latitudePosition,
            pickUpLocation!.longitudePosition,
            dropOffDestinationLocation!.latitudePosition,
            dropOffDestinationLocation!.longitudePosition,
            _selectedDate1,
            _selectedTime1!.format(context));

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
        cMethods.displaySnackBar("Your advance booking has posted!", context);
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
