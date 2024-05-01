import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/pages/booking_screen.dart';
import 'package:passenger/pages/home_page.dart';
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
  TextEditingController destinationTextEditingController = TextEditingController();
  List<PredictionModel> dropOffPredictionsPlacesList = [];

  searchLocation(String locationName) async {
    if (locationName.length > 1) {
      String apiPlacesUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:ph";

      var responseFromPlacesAPI = await CommonMethods.sendRequestToAPI(apiPlacesUrl);
      if (responseFromPlacesAPI == "error") {
        return;
      }
      if (responseFromPlacesAPI["status"] == "OK") {
        var predictionResultInJson = responseFromPlacesAPI["predictions"];
        var predictionsList = (predictionResultInJson as List)
            .map((eachPlacePrediction) =>
                PredictionModel.fromJson(eachPlacePrediction))
            .toList();

        setState(() {
          dropOffPredictionsPlacesList = predictionsList;
        });
      }
    }
  }

    void navigateToHomePage() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  void initState() {
    super.initState();
    // Automatically show the ride options dialog when the page is loaded
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      showRideOptionsDialog(context);
    });
  }

  void showRideOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Schedule a Ride'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookingScreen()),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/ridenow.png",
                          height: 50,
                          width: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Ride Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookingScreen()),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/calendar.png",
                          height: 50,
                          width: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Advance Booking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
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
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Set Dropoff Location",
                    style: TextStyle(
                      fontSize: 24,
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
