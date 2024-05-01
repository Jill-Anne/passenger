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
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/authentication/login_screen.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/methods/manage_drivers_methods.dart';
import 'package:passenger/methods/push_notification_service.dart';
import 'package:passenger/models/direction_details.dart';
import 'package:passenger/pages/online_nearby_drivers.dart';
import 'package:passenger/pages/search_destination%20_page.dart';
import 'package:passenger/widgets/info_dialog.dart';
import 'package:passenger/widgets/loading_dialog.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:passenger/widgets/prediction_place_ui.dart';


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

  makeDriverNearbyCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: const Size(0.1, 0.1));
      BitmapDescriptor.fromAssetImage(
              configuration, "assets/images/pin4.png")
          .then((iconImage) {
        carIconNearbyDriver = iconImage;
      });
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

//WHAT IS THIS????????
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
     builder: (BuildContext context) => CustomLoadingAnimation(),
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

    // Restart.restartApp();
  }

  cancelRideRequest() {
    //remove ride request from database
    tripRequestRef!.remove();

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
      "carDetails": "",
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
    };

    print("Drop-off address: ${dataMap["dropOffAddress"]}");

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
    });
  }

  displayTripDetailsContainer() {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var userPickUpLocationLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if (directionDetailsPickup == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            "Driver is Coming - ${directionDetailsPickup.durationTextString}";
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

  noDriverAvailable() async {
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

    if (result == true) {
      resetAppNow();
    }
  }

  searchDriver() {
    if (availableNearbyOnlineDriversList!.isEmpty) {
      cancelRideRequest();
      noDriverAvailable();
      return;
    }

    var currentDriver = availableNearbyOnlineDriversList!.removeAt(0);
    sendNotificationToDriver(currentDriver);
  }

  void sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    print(
        'sendNotificationToDriver called for driver UID: ${currentDriver.uidDriver}'); // Debug print

    // Update driver's newTripStatus - assign tripID to current driver
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("driversAccount")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key).then((_) {
      print(
          'newTripStatus updated for driver UID: ${currentDriver.uidDriver} with tripID: ${tripRequestRef!.key}'); // Debug print
    }).catchError((error) {
      print(
          'Error updating newTripStatus for driver UID: ${currentDriver.uidDriver}: $error'); // Debug print on error
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
            'Device token retrieved for driver UID: ${currentDriver.uidDriver}: $deviceToken'); // Debug print

        // Send notification
        PushNotificationService.sendNotificationToSelectedDriver(
          deviceToken,
          context,
          tripRequestRef!.key.toString(),
        );
      } else {
        print(
            'Device token not found for driver UID: ${currentDriver.uidDriver}'); // Debug print
        return;
      }
    }).catchError((error) {
      print(
          'Error retrieving device token for driver UID: ${currentDriver.uidDriver}: $error'); // Debug print on error
    });

    const oneTickPerSec = Duration(seconds: 1);

    var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
      requestTimeoutDriver = requestTimeoutDriver - 1;

      //when trip request is not requesting means trip request cancelled - stop timer
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

        //send notification to next nearest online available driver
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
                            userName,
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

              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

              const SizedBox(
                height: 10,
              ),

//body
              ListTile(
                leading: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.info,
                    color: Colors.grey,
                  ),
                ),
                title: const Text(
                  "About",
                  style: TextStyle(color: Colors.grey),
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
                      color: Color.fromARGB(255, 255, 255, 255),
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
            child: GestureDetector(
              onTap: () async {
                var responseFromSearchPage = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => SearchDestinationPage()),
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
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
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
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Where do you want to go?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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
                    ),
                    SizedBox(height: 20), // Add spacing between search container and recent locations
                    // Recent Locations section
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Recent Locations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 150, // Set the height as per your requirement
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            /*child:  Your UI for recent locations goes here */
                          ),
                        ],
                      ),
                    ),
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
  child: Container(
    height: rideDetailsContainerHeight,
    decoration: const BoxDecoration(
      color: Colors.white, // Set background color to white
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
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
                Icon(Icons.arrow_forward), // Icon indicating that clicking will lead to another page
              ],
            ),
            SizedBox(height: 16), // Added for spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 10,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.90, // Adjusted width for better visibility
                  color: Colors.white, // Adjusted for consistency with background
                  child: Padding(
                    padding: const EdgeInsets.all(16), // Increased padding for better layout
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              tripDirectionDetailsInfo?.distanceTextString ?? "",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8), // Added for spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              tripDirectionDetailsInfo?.durationTextString ?? "",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8), // Added for spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              tripDirectionDetailsInfo != null ? "\PHP ${cMethods.calculateFareAmount(tripDirectionDetailsInfo!).toString()}" : "",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16), // Added for spacing
                        Divider(), // Divider line
                        SizedBox(height: 16), // Added for spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Do you want to share your ride?",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Driver can accept other \npassengers within the route \nto the destination",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: true, // Set the initial value of the switch
                              onChanged: (bool newValue) {
                                // Add functionality here
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16), // Added for spacing
                        // CONFIRM BOOKING BUTTON
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10), // Adjusted margin for better spacing
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
                                  ManageDriversMethods.nearbyOnlineDriversList;

                              //search driver
                              searchDriver();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    decoration: BoxDecoration(
      color: const Color.fromARGB(137, 255, 255, 255),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                          color: Color.fromARGB(255, 1, 42, 123).withOpacity(0.4),
                          width: 2,
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 18, 0, 88)),
                    strokeWidth: 3,
                    value: null,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              displayUserRideDetailsContainer();
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
              child: Icon(
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
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            // Trip status display text
            Text(
              tripStatusDisplay,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Divider(
              height: 10,
              color: Colors.grey[400],
              thickness: 1,
            ),
            const SizedBox(
              height: 20,
            ),
            // Image - Driver name and car details
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              decoration: BoxDecoration(
                border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      photoDriver == ''
                          ? "https://firebasestorage.googleapis.com/v0/b/flutter-uber-clone-with-admin.appspot.com/o/avatarman.png?alt=media&token=7a04943c-a566-45d3-b820-d33da3b105c7"
                          : photoDriver,
                    ),
                    radius: 30,
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "ID: $idNumber",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        "Body Number: $bodyNumber",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Divider(
              height: 1,
              color: Colors.grey[400],
              thickness: 1,
            ),
            const SizedBox(
              height: 15,
            ),
            // Call driver button
            GestureDetector(
              onTap: () {
                launchUrl(Uri.parse("tel://$phoneNumberDriver"));
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 1, 42, 123),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Call Driver",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
  ),
),

        ],
      ),
    );
  }
}
