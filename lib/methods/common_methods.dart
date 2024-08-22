import 'dart:convert'; // Importing dart:convert for JSON encoding/decoding.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Importing a package for checking network connectivity.
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart'; // Importing Flutter material package for UI components.
import 'package:geolocator/geolocator.dart'; // Importing geolocator package for getting device's location.
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart'
    as http; // Importing http package for making HTTP requests.
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/models/address_model.dart';
import 'package:passenger/models/direction_details.dart';
import 'package:provider/provider.dart'; // Importing global variables.

class CommonMethods {
  // Method for checking connectivity.
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity()
        .checkConnectivity(); // Checking the network connectivity status.

    // If no mobile or wifi connectivity.
    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return; // If the widget is not mounted, return.
      displaySnackBar(
          "Your Internet is not Available. Check your connection. Try Again.", // Displaying a message for the user.
          context); // Passing the context to display the snackbar.
    }
  }

  // Method for displaying a snackbar.
  displaySnackBar(String messageText, BuildContext context) {
    var snackBar =
        SnackBar(content: Text(messageText)); // Creating a snackbar widget.
    ScaffoldMessenger.of(context)
        .showSnackBar(snackBar); // Displaying the snackbar.
  }

  // Send GET requests to an API and handle the response.
  // Method for sending a request to an API.
  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(
        Uri.parse(apiUrl)); // Sending a GET request to the specified API URL.

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi =
            responseFromAPI.body; // Getting data from the API response.
        var dataDecoded = jsonDecode(dataFromApi); // Decoding the JSON data.
        return dataDecoded; // Returning the decoded data.
      } else {
        return "error"; // Returning an error message if the response status code is not 200.
      }
    } catch (errorMsg) {
      return "error"; // Returning an error message if an exception occurs.
    }
  }

  /// Reverse GeoCoding
  // Method for converting geographic coordinates into human-readable address.
  static Future<String> convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    String humanReadableAddress =
        ""; // Initializing a variable to store the human-readable address.

    String apiGeoCodingUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey"; // Constructing the API URL for reverse geocoding.

    var responseFromAPI = await sendRequestToAPI(
        apiGeoCodingUrl); // Sending a request to the API for reverse geocoding.

    if (responseFromAPI != "error") {
      humanReadableAddress = responseFromAPI["results"][0][
          "formatted_address"]; // Extracting the human-readable address from the API response.
      print("humanReadableAddress = " +
          humanReadableAddress); // Printing the human-readable address.
    }

    AddressModel model = AddressModel();
    model.humanReadableAddress = humanReadableAddress;
    model.placeName = humanReadableAddress;
    model.longitudePosition = position.longitude;
    model.latitudePosition = position.latitude;

    Provider.of<AppInfo>(context, listen: false).updatePickUpLocation(model);

    return humanReadableAddress; // Returning the human-readable address.
  }

  // DIRECTION API
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    // SENT REQUEST TO DIRECTION API
    String urlDirectionsAPI =
        "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$googleMapKey";

    // JSON FORMAT = WE GET RESPONSE FROM DIRECTION API
    var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

    if (responseFromDirectionsAPI == "error") {
      return null;
    }

    // IF RESPONSE SUCCESS WE GET THIS:
    // MAKE IT NOT JSON FORMAT OR FORMAL THRU DIRECTION DETAILS MODELS
    DirectionDetails detailsModel = DirectionDetails();

    detailsModel.distanceTextString =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints =
        responseFromDirectionsAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }

Future<double> calculateFareAmount(DirectionDetails directionDetails) async {
  try {
    // Retrieve the fare parameters from Firebase Firestore
    DocumentSnapshot fareData = await FirebaseFirestore.instance
        .collection('fareParameters')
        .doc('currentParameters')
        .get();

    if (!fareData.exists) {
      throw Exception('Fare parameters not found');
    }

    // Log retrieved fare data for debugging
    print('Retrieved fare data: ${fareData.data()}');

    // Ensure values are retrieved as double, handle possible type issues
    double distancePerKmAmount;
    double baseFareAmount;

    try {
      distancePerKmAmount = (fareData['distancePerKmAmount'] as num).toDouble();
    } catch (e) {
      print("Error converting distancePerKmAmount: $e");
      distancePerKmAmount = 0.0;
    }

    try {
      baseFareAmount = (fareData['baseFareAmount'] as num).toDouble();
    } catch (e) {
      print("Error converting baseFareAmount: $e");
      baseFareAmount = 0.0;
    }

    // Distance in km
    double distanceInKm;
    try {
      distanceInKm = directionDetails.distanceValueDigits! / 1000;
    } catch (e) {
      print("Error calculating distanceInKm: $e");
      distanceInKm = 0.0;
    }

    // Determine if distance exceeds the base fare threshold
    double distanceThreshold = 1.87; // Distance threshold for base fare

    double totalDistanceTravelFareAmount;
    if (distanceInKm > distanceThreshold) {
      // Calculate the fare for the distance beyond the base threshold
      double distanceBeyondThreshold = distanceInKm - distanceThreshold;
      totalDistanceTravelFareAmount = distanceBeyondThreshold * distancePerKmAmount;
    } else {
      // No additional fare for distances within the base threshold
      totalDistanceTravelFareAmount = 0;
    }

    // Calculate the overall total fare amount (base fare + distance-based fare)
    double overAllTotalFareAmount = baseFareAmount + totalDistanceTravelFareAmount;

    // Round the fare amount to the nearest whole number
    overAllTotalFareAmount = overAllTotalFareAmount.roundToDouble();

    // Save the calculated fare amount to Firestore
    await FirebaseFirestore.instance
        .collection('currentFare')
        .doc('latestFare')
        .set({'amount': overAllTotalFareAmount});

    print('Calculated fare amount: PHP $overAllTotalFareAmount');
    return overAllTotalFareAmount;
  } catch (e) {
    print("Error fetching fare parameters or calculating fare: $e");
    return 0.0; // Return a default value or handle the error appropriately
  }
}


}
