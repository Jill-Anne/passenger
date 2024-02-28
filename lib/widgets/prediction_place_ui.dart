import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/models/address_model.dart';
import 'package:passenger/models/prediction_model.dart';
import 'package:passenger/widgets/loading_dialog.dart';
import 'package:provider/provider.dart';

class PredictionPlaceUI extends StatefulWidget {
  PredictionModel? predictedPlaceData;

  PredictionPlaceUI({
    super.key,
    this.predictedPlaceData,
  });

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
  ///Place Details - Places API
  fetchClickedPlaceDetails(String placeID) async
  {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
    );

    String urlPlaceDetailsAPI = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";

    var responseFromPlaceDetailsAPI = await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);

    Navigator.pop(context);

    if(responseFromPlaceDetailsAPI == "error")
    {
      return;
    }

    if(responseFromPlaceDetailsAPI["status"] == "OK")
    {
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
    return Padding(
      padding: const EdgeInsets.only(top: 10), // Add space at the top
      child: ElevatedButton(
        onPressed: () {
          fetchClickedPlaceDetails(widget.predictedPlaceData!.place_id.toString());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
        ),
        child: SizedBox(
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.share_location,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    width: 13,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          widget.predictedPlaceData!.main_text.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          widget.predictedPlaceData!.secondary_text.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
