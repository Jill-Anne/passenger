import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps package for LatLng
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

  PredictionPlaceUI({
    super.key,
    this.predictedPlaceData,
  });

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
  // Define the LatLngBounds for Valenzuela
  final LatLngBounds valenzuelaBounds = LatLngBounds(
    southwest: LatLng(14.6445, 120.9545),  // Southwest corner
    northeast: LatLng(14.7406, 121.0467),  // Northeast corner
  );

  /// Place Details - Places API
  fetchClickedPlaceDetails(String placeID) async {
    if (!mounted) return; // Check if the widget is still mounted

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Getting details..."),
    );

    String urlPlaceDetailsAPI =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";

    var responseFromPlaceDetailsAPI =
        await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);

    Navigator.pop(context);

    if (!mounted) return; // Check if the widget is still mounted after async operation

    if (responseFromPlaceDetailsAPI == "error") {
      return;
    }

    if (responseFromPlaceDetailsAPI["status"] == "OK") {
      double latitude = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lat"];
      double longitude = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lng"];
      LatLng placeLocation = LatLng(latitude, longitude);

      // Check if the selected place is within the Valenzuela bounds
      if (!valenzuelaBounds.contains(placeLocation)) {
        // If the place is outside Valenzuela, show an error message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text("The selected location is outside Valenzuela."),
        //   ),
        // );

         Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPage()),
    );
        return; // Stop further processing
      }

      // Continue if the place is within Valenzuela
      AddressModel dropOffLocation = AddressModel();

      dropOffLocation.placeName = responseFromPlaceDetailsAPI["result"]["name"];
      dropOffLocation.latitudePosition = latitude;
      dropOffLocation.longitudePosition = longitude;
      dropOffLocation.placeID = placeID;

      Provider.of<AppInfo>(context, listen: false)
          .updateDropOffLocation(dropOffLocation);

      if (!mounted) return; // Check if the widget is still mounted before navigating

      Future.delayed(Duration.zero, () {
        Navigator.pop(context, "placeSelected");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10), // Add space at the top
      child: ElevatedButton(
        onPressed: () {
          fetchClickedPlaceDetails(widget.predictedPlaceData!.place_id.toString());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Set background to white
          elevation: 4, // Add elevation for shadow
          padding: const EdgeInsets.all(16), // Padding inside the button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on, // Change the icon to location_on
              color: Color.fromARGB(255, 1, 42, 123), // Use the specified blue color
              size: 30, // Larger icon size
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                children: [
                  Text(
                    widget.predictedPlaceData!.main_text.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold, // Bold text for main text
                    ),
                  ),
                  const SizedBox(height: 4), // Smaller space between texts
                  Text(
                    widget.predictedPlaceData!.secondary_text.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey, // Grey color for secondary text
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
