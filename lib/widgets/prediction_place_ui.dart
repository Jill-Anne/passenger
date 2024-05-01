import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/models/address_model.dart';
import 'package:passenger/models/prediction_model.dart';
import 'package:provider/provider.dart';

class PredictionPlaceUI extends StatelessWidget {
  final PredictionModel? predictedPlaceData;

  const PredictionPlaceUI({
    Key? key,
    this.predictedPlaceData, 
  }) : super(key: key);

  /// Place Details - Places API
  fetchClickedPlaceDetails(String placeID, BuildContext context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => CustomLoadingAnimation(),
    );

    String urlPlaceDetailsAPI =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";

    var responseFromPlaceDetailsAPI = await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);

    Navigator.pop(context);

    if (responseFromPlaceDetailsAPI == "error") {
      return;
    }

    if (responseFromPlaceDetailsAPI["status"] == "OK") {
      AddressModel dropOffLocation = AddressModel();

      dropOffLocation.placeName = responseFromPlaceDetailsAPI["result"]["name"];
      dropOffLocation.latitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lat"];
      dropOffLocation.longitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lng"];
      dropOffLocation.placeID = placeID;

      Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(dropOffLocation);

      Navigator.pop(context, "placeSelected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          fetchClickedPlaceDetails(predictedPlaceData!.place_id.toString(), context);
        },
        child: ListTile(
          leading: Icon(Icons.location_on, color: Color.fromARGB(255, 1, 42, 123)),
          title: Text(
            predictedPlaceData!.main_text ?? "Unknown location",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            predictedPlaceData!.secondary_text ?? "No details",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// Custom loading animation widget
class CustomLoadingAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ),
    );
  }
}
