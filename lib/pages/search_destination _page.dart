import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/models/prediction_model.dart';
import 'package:passenger/pages/home_page.dart';
import 'package:passenger/widgets/dialog_utils.dart';
import 'package:passenger/widgets/prediction_place_ui.dart';
import 'package:provider/provider.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, widget) {
        Widget error = const Text('...rendering error...');
        if (widget is Scaffold || widget is Navigator) {
          error = Scaffold(body: Center(child: error));
        }
        ErrorWidget.builder = (errorDetails) => error;
        if (widget != null) return widget;
        throw StateError('widget is null');
      },
    );
  }
}

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({Key? key}) : super(key: key);

  @override
  State<SearchDestinationPage> createState() => SearchDestinationPageState();
}

class SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();
  List<PredictionModel> dropOffPredictionsPlacesList = [];
  String? selectedDropOffLocation;

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
      //No error occurred
      if (responseFromPlacesAPI["status"] == "OK") {
        var predictionResultInJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionResultInJson as List)
            .map((eachPlacePrediction) =>
                PredictionModel.fromJson(eachPlacePrediction))
            .toList();

        setState(() {
          dropOffPredictionsPlacesList = predictionsList;
        });

        // print("predictionResultinJSON = " + predictionResultInJson.toString());
      }
    }
  }

  void navigateToHomePage() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()));
  }

  @override
  void initState() {
    super.initState();

    // Automatically show the ride options dialog when the page is loaded
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider.of<AppInfo>(context, listen: false)
        .pickUpLocation!.humanReadableAddress ?? "";
    pickUpTextEditingController.text = userAddress;

return Scaffold(
  body: Column(
    children: [
      Card(
        color: Color.fromARGB(255, 1, 42, 123), // Blue color for the card
        elevation: 5,
        margin: EdgeInsets.only(top: 0, left: 0, right: 0), // No margins for the card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color.fromARGB(255, 255, 255, 255),
                      size: 25,
                    ),
                  ),
                  SizedBox(height: 100),
                  const SizedBox(width: 45),
                  const Text(
                    "Set Dropoff Location",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
                SizedBox(height: 20),
                TextFormField(
                  controller: pickUpTextEditingController,
                  style: TextStyle(color: Colors.white), // Set input text color to white
                  decoration: InputDecoration(
                    labelText: "Pickup Address",
                    labelStyle: TextStyle(color: Colors.white), // Label text color is white
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: Image.asset(
                        "assets/images/initial.png",
                        height: 16,
                        width: 16,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: destinationTextEditingController,
                  style: TextStyle(color: Colors.white), // Set input text color to white
                  onChanged: (inputText) {
                    searchLocation(inputText);
                  },
                  decoration: InputDecoration(
                    labelText: "Destination Address",
                    labelStyle: TextStyle(color: Colors.white), // Label text color is white
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: Image.asset(
                        "assets/images/final.png",
                        height: 16,
                        width: 16,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
          // Drop-off location predictions
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: dropOffPredictionsPlacesList.isNotEmpty
                  ? ListView.builder(
                      itemCount: dropOffPredictionsPlacesList.length,
                      itemBuilder: (context, index) {
                        return PredictionPlaceUI(
                          predictedPlaceData: dropOffPredictionsPlacesList[index],
                        );
                      },
                    )
                  : Container(),
            ),
          ),
        ],
      ),
    );

  }
}