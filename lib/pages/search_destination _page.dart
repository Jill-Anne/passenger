import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/models/prediction_model.dart';
import 'package:passenger/widgets/prediction_place_ui.dart';
import 'package:provider/provider.dart';

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({super.key});

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();
  List<PredictionModel> dropOffPredictionsPlacesList = [];

  ///Places API - Place AutoComplete
  searchLocation(String locationName) async {
    if (locationName.length > 1) {
      String apiPlacesUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:ph";

//SEND REQUEST TO API
      var responseFromPlacesAPI =
          await CommonMethods.sendRequestToAPI(apiPlacesUrl);
//check if its error
      if (responseFromPlacesAPI == "error") {
        return;
        //do nothing
      }
//No error occured
      if (responseFromPlacesAPI["status"] == "OK") {
        var predictionResultInJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionResultInJson as List)
            .map((eachPlacePrediction) =>
                PredictionModel.fromJson(eachPlacePrediction))
            .toList();

        setState(() {
          dropOffPredictionsPlacesList = predictionsList;
        });

        print("predictionResultinJSON = " + predictionResultInJson.toString());
      }
    }
  }

@override
Widget build(BuildContext context) {
  String userAddress = Provider.of<AppInfo>(context, listen: false)
    .pickUpLocation!.humanReadableAddress ?? "";
  pickUpTextEditingController.text = userAddress;

  return Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            Card(
              elevation: 0, // Remove elevation
              child: Container(
                height: 230,
                color: Colors.white, // Set container background to white
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 24, top: 48, right: 24, bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 6,
                      ),
                      //icon button - title
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const Center(
                            child: Text(
                              "Set Dropoff Location",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      //pickup text field
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/initial.png",
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(
                            width: 18,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey), // Add border
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: TextField(
                                  controller: pickUpTextEditingController,
                                  decoration: InputDecoration(
                                    hintText: "Pickup Address",
                                    border: InputBorder.none, // Remove border
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(
                                        left: 11, top: 9, bottom: 9),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 11,
                      ),
                      //destination text field
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/final.png",
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(
                            width: 18,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey), // Add border
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: TextField(
                                  controller:
                                  destinationTextEditingController,
                                  onChanged: (inputText) {
                                    searchLocation(inputText);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Destination Address",
                                    border: InputBorder.none, // Remove border
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(
                                        left: 11, top: 9, bottom: 9),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            //display prediction results for destination place
            (dropOffPredictionsPlacesList.length > 0)
                ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 20), // Adjust padding
              child: SizedBox(
                height: 500, // Set a fixed height to prevent overflow
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PredictionPlaceUI(
                          predictedPlaceData: dropOffPredictionsPlacesList[index],
                        ),
                    
                      ],
                    );
                  },
                  itemCount: dropOffPredictionsPlacesList.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                ),
              ),
            )
                : Container(),
          ],
        ),
      ),
    ),
  );
}

}
