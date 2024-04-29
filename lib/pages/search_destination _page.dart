import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/models/prediction_model.dart';
import 'package:passenger/pages/home_page.dart';
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
  late List<DateTime?> _dialogCalendarPickerValue;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _selectedTime;
  

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
    _dialogCalendarPickerValue = [];
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    // Automatically show the ride options dialog when the page is loaded
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider.of<AppInfo>(context, listen: false)
            .pickUpLocation!
            .humanReadableAddress ??
        "";
    pickUpTextEditingController.text = userAddress;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: navigateToHomePage,
        ),
        title: GestureDetector(
          onTap: () {
            // Always show the ride options dialog when the arrow is tapped
            showRideOptionsDialog(context);
          },
          child: Row(
            children: [
              Text(selectedDropOffLocation ?? "Ride Now"),
              Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              Card(
                elevation: 0,
                child: Container(
                  height: 230,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 24, top: 48, right: 24, bottom: 20),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 6,
                        ),
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
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: TextField(
                                    controller: pickUpTextEditingController,
                                    decoration: InputDecoration(
                                      hintText: "Pickup Address",
                                      border: InputBorder.none,
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
                                  border: Border.all(color: Colors.grey),
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
                                      border: InputBorder.none,
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
              (dropOffPredictionsPlacesList.length > 0)
                  ? Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 20),
                      child: SizedBox(
                        height: 500,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(0),
                          itemBuilder: (context, index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PredictionPlaceUI(
                                  predictedPlaceData:
                                      dropOffPredictionsPlacesList[index],
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

Widget _buildCalendarDialogButton() {
  const dayTextStyle =
      TextStyle(color: Colors.black, fontWeight: FontWeight.w700);
  final prevDayTextStyle =
      TextStyle(color: Colors.grey, fontWeight: FontWeight.w600);
  final weekendTextStyle =
      TextStyle(color: Colors.black, fontWeight: FontWeight.w600);
  final anniversaryTextStyle = TextStyle(
    color: Colors.red[400],
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
  );
  final config = CalendarDatePicker2WithActionButtonsConfig(
    calendarViewScrollPhysics: const NeverScrollableScrollPhysics(),
    dayTextStyle: dayTextStyle,
    calendarType: CalendarDatePicker2Type.range,
    selectedDayHighlightColor: Colors.purple[800],
    closeDialogOnCancelTapped: true,
    firstDayOfWeek: 1,
    weekdayLabelTextStyle: const TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.bold,
    ),
    controlsTextStyle: const TextStyle(
      color: Colors.black,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    ),
    centerAlignModePicker: true,
    customModePickerIcon: const SizedBox(),
    selectedDayTextStyle: dayTextStyle.copyWith(color: Colors.grey),
    dayTextStylePredicate: ({required date}) {
      TextStyle? textStyle;
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        textStyle = weekendTextStyle;
      }
      if (date.isBefore(DateTime.now().subtract(const Duration(days: 1))) ||
          date.year < DateTime.now().year) {
        textStyle = prevDayTextStyle;
      }
      if (DateUtils.isSameDay(date, DateTime(2021, 1, 25))) {
        textStyle = anniversaryTextStyle;
      }
      return textStyle;
    },
  );

  return Center(
    child: Stack(
      children: [
        SizedBox(
          height: 400,
          child: Material(
            child: CalendarDatePicker2(
              config: config,
              value: _dialogCalendarPickerValue,
              onValueChanged: (values) {
  if (values != null && values.length == 2) {
    setState(() {
      _dialogCalendarPickerValue = values;
      _startDate = values[0]!;
      _endDate = values[1]!;
    });
  } else if (values != null && values.length == 1) {
    setState(() {
      _dialogCalendarPickerValue = values;
      _startDate = values[0]!;
      _endDate = values[0]!; // For solo date, set end date to start date
    });
  }
},

            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: SizedBox(height: 50),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: _buildCalendarDialogButtons(),
        ),
      ],
    ),
  );
}

  Widget _buildCalendarDialogButtons() {
    return Container(
      // Adjust the width of Container to change the width of the buttons
      width: double.infinity, // Adjust the width of the buttons here
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cancel button pops the dialog
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _navigateToTimeSpinner(context,
                  closeCalendarDialog: true); // Navigate to time spinner
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  void showRideOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Schedule a Ride'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _buildCalendarDialogButton();
                      },
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
                    // Handle advance booking
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

  void _navigateToTimeSpinner(BuildContext context,
      {required bool closeCalendarDialog}) {
    if (closeCalendarDialog) {
      Navigator.of(context).pop(); // Close the calendar dialog
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: buildTime(),
        );
      },
    );
  }

  Widget buildTime() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
        color: Colors.lightBlue[100],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Time',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildTimePickerSpinner(),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CANCEL'),
              ),
ElevatedButton(
  onPressed: () {
    _showConfirmationDialog(
      context,
      _startDate,
      _endDate,
      closeTimeSpinnerDialog: true,
      resetDatesCallback: () {
        setState(() {
          _startDate = DateTime.now(); // Reset start date
          _endDate = DateTime.now(); // Reset end date
          print('Dates reset: $_startDate - $_endDate');
          _dialogCalendarPickerValue = []; // Reset calendar value
        });
      },
    );
  },
  child: Text('BOOK'),
),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerSpinner() {
    // Define parameters inside the widget
    bool isShowSeconds = false;
    bool is24HourMode = false;
    TextStyle normalTextStyle = TextStyle(fontSize: 24, color: Colors.black);
    TextStyle highlightedTextStyle =
        TextStyle(fontSize: 28, color: Colors.blue);
    double spacing = 40;
    double itemHeight = 60;
    bool isForce2Digits = true;

    return TimePickerSpinner(
      isShowSeconds: isShowSeconds,
      is24HourMode: is24HourMode,
      normalTextStyle: normalTextStyle,
      highlightedTextStyle: highlightedTextStyle,
      spacing: spacing,
      itemHeight: itemHeight,
      isForce2Digits: isForce2Digits,
      onTimeChange: (time) {
        setState(() {
          _selectedTime = TimeOfDay.fromDateTime(time);
        });
      },
    );
  }

void _showConfirmationDialog(BuildContext context, DateTime startDate, DateTime endDate,
    {required bool closeTimeSpinnerDialog, required VoidCallback resetDatesCallback}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              startDate == endDate
                  ? 'Selected Date: ${startDate.day}/${startDate.month}/${startDate.year}' // Display solo date if start and end date are the same
                  : 'Selected Date Range: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}', // Display date range if different start and end date
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Selected Time: ${_selectedTime.format(context)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              print('Booking confirmed');
              resetDatesCallback(); // Reset the selected dates
              Navigator.of(context).pop();
              if (closeTimeSpinnerDialog) {
                Navigator.of(context).pop();
              }
            },
            child: Text('BOOK'),
          ),
        ],
      );
    },
  );
}



}
