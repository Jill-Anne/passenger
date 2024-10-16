import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/models/address_model.dart';
import 'package:passenger/models/prediction_model.dart';
import 'package:passenger/pages/outside_location.dart';
import 'package:passenger/widgets/loading_dialog.dart';
import 'package:provider/provider.dart';

class PredictionPlaceUI extends StatefulWidget {
  final PredictionModel? predictedPlaceData;

  PredictionPlaceUI({super.key, this.predictedPlaceData});

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
  // Define the original LatLngBounds for Valenzuela
  final LatLngBounds valenzuelaBounds = LatLngBounds(
    southwest: LatLng(14.6445, 120.9545), // Southwest corner
    northeast: LatLng(14.7406, 121.0467), // Northeast corner
  );

  // Define a buffer in degrees (adjust as necessary)
 final double bufferDegrees = 0.009; // About 1 kilometer

  // Expand the bounds by a given buffer
  LatLngBounds expandBounds(LatLngBounds bounds) {
    return LatLngBounds(
      southwest: LatLng(
        bounds.southwest.latitude - bufferDegrees,
        bounds.southwest.longitude - bufferDegrees,
      ),
      northeast: LatLng(
        bounds.northeast.latitude + bufferDegrees,
        bounds.northeast.longitude + bufferDegrees,
      ),
    );
  }

  // Load GeoJSON data
  Future<Map<String, dynamic>> loadGeoJson() async {
    try {
      final String response = await rootBundle.loadString('assets/images/Valenzuelaboundary');
      print("GeoJSON loaded successfully.");
      return json.decode(response);
    } catch (e) {
      print("Error loading GeoJSON: $e");
      return {};
    }
  }

  // Extract coordinates from GeoJSON
  Future<List<LatLng>> extractCoordinates() async {
    final geoJson = await loadGeoJson();
    List<LatLng> coordinates = [];

    if (geoJson.isNotEmpty) {
      print("Extracting coordinates from GeoJSON...");
      for (var feature in geoJson['features']) {
        var geometry = feature['geometry'];
        if (geometry['type'] == 'Polygon') {
          var coords = geometry['coordinates'][0]; // Assuming it's a single polygon
          for (var point in coords) {
            LatLng latLngPoint = LatLng(point[1], point[0]); // Convert to LatLng
            coordinates.add(latLngPoint);
            print("Extracted coordinate: $latLngPoint");
          }
        }
      }
    } else {
      print("GeoJSON is empty or not loaded correctly.");
    }

    return coordinates;
  }

  // Check if a point is within the polygon
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final LatLng pi = polygon[i];
      final LatLng pj = polygon[j];
      if ((pi.longitude > point.longitude) != (pj.longitude > point.longitude) &&
          (point.latitude < (pj.latitude - pi.latitude) * (point.longitude - pi.longitude) / (pj.longitude - pi.longitude) + pi.latitude)) {
        isInside = !isInside;
      }
    }
    print("Point $point is ${isInside ? 'inside' : 'outside'} the polygon.");
    return isInside;
  }

  /// Place Details - Places API
 fetchClickedPlaceDetails(String placeID) async {
  if (!mounted) return; // Check if the widget is still mounted

  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
  );

  String urlPlaceDetailsAPI = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";

  var responseFromPlaceDetailsAPI = await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);

  Navigator.pop(context);

  if (!mounted) return; // Check if the widget is still mounted after async operation

  if (responseFromPlaceDetailsAPI == "error") {
    print("Error fetching place details.");
    return;
  }

  if (responseFromPlaceDetailsAPI["status"] == "OK") {
    double latitude = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lat"];
    double longitude = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lng"];
    LatLng placeLocation = LatLng(latitude, longitude);

    // Debug logs
    print("Place Location: $placeLocation");
    print("Valenzuela Bounds Southwest: ${valenzuelaBounds.southwest}");
    print("Valenzuela Bounds Northeast: ${valenzuelaBounds.northeast}");

    // Check if "Valenzuela" is in the place name or address
    String placeName = responseFromPlaceDetailsAPI["result"]["name"].toString().toLowerCase();
    String placeAddress = responseFromPlaceDetailsAPI["result"]["formatted_address"].toString().toLowerCase();

    if (placeName.contains("valenzuela") || placeAddress.contains("valenzuela")) {
      // If the place name or address includes "Valenzuela", proceed
      print("Place is recognized as Valenzuela based on name/address.");
    } else {
      // Load Valenzuela polygon coordinates
      List<LatLng> valenzuelaCoords = await extractCoordinates();

      // Expand the bounds for detection
      LatLngBounds expandedBounds = expandBounds(valenzuelaBounds);

      // Check if the selected place is within the expanded Valenzuela bounds and polygon
      if (!expandedBounds.contains(placeLocation) || !isPointInPolygon(placeLocation, valenzuelaCoords)) {
        print("Selected location is outside Valenzuela.");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LocationPage()),
        );
        return; // Stop further processing
      }
    }

    // Continue if the place is within Valenzuela or recognized as Valenzuela
    AddressModel dropOffLocation = AddressModel();
    dropOffLocation.placeName = responseFromPlaceDetailsAPI["result"]["name"];
    dropOffLocation.latitudePosition = latitude;
    dropOffLocation.longitudePosition = longitude;
    dropOffLocation.placeID = placeID;

    Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(dropOffLocation);

    if (!mounted) return; // Check if the widget is still mounted before navigating

    Future.delayed(Duration.zero, () {
      Navigator.pop(context, "placeSelected");
    });
  }
}

  // Define the specific areas to exclude
  final List<LatLng> excludedAreas = [
    LatLng(14.6680747, 120.9658454), // Example excluded location
    LatLng(14.6610, 120.9600),       // Another example
    LatLng(14.6700, 120.9700),       // Add more as needed
    LatLng(14.6750, 120.9500),       // Another location to exclude
    LatLng(14.6400, 120.9600),    
    LatLng(14.6489906, 120.9906299), // Add any additional locations
  ];

  bool isLocationExcluded(LatLng location) {
    return excludedAreas.any((excludedLocation) {
      return (location.latitude == excludedLocation.latitude && location.longitude == excludedLocation.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ElevatedButton(
        onPressed: () {
          fetchClickedPlaceDetails(widget.predictedPlaceData!.place_id.toString());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Color.fromARGB(255, 1, 42, 123),
              size: 30,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.predictedPlaceData!.main_text.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.predictedPlaceData!.secondary_text.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
