import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/pages/home_page.dart';
import 'package:passenger/services/add_advancebooking.dart';
import 'package:passenger/widgets/termsConditionText.dart';
import 'package:provider/provider.dart';

class TermsConditionsPage extends StatefulWidget {
  String name;
  String phone;

  TermsConditionsPage({
    super.key,
    required this.name,
    required this.phone,
  });

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  CommonMethods cMethods = CommonMethods();
 @override
 
 
Widget build(BuildContext context) {


      // Set the status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 1, 42, 123), // Set a color or transparent
      statusBarIconBrightness: Brightness.light,
    ));

  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false, // Prevents the default back button
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 7), // Adjust this for the desired spacing
          Expanded(
 child: Padding(
  padding: const EdgeInsets.only(top: 0),
  child: Container(
    alignment: Alignment.center, // Center the text within the container
    child: const Text(
      'Terms and Conditions of Service Ride',
      textAlign: TextAlign.center, // Center the text within itself
      style: TextStyle(
      //  color: Color.fromARGB(255, 18, 2, 56),
        fontSize: 18, // Adjust the font size as needed
        fontWeight: FontWeight.bold,
      ),
      maxLines: 3, // Allow for text wrapping
      overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
    ),
  ),
),
          ),

        ],
      ),
    ),

    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
               SizedBox(width: 40),
              
 TermsAndConditions(), 
  SizedBox(height: 15),
              Container(
                width: 275,
                margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10), // Adjusted margin for better spacing
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    _selectDateRange(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(
                        0xFF2E3192), // Use the color from your reusable widget
                  ),
                 
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Accept', // Custom text for the booking action
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
    );
  }

DateTime? _selectedDate1; // For single date selection
DateTimeRange? _selectedDateRange; // For date range selection
TimeOfDay? _selectedTime1; // For time selection


Future<void> _selectDateRange(BuildContext context) async {
  // Show the date range picker
  final DateTimeRange? pickedDateRange = await showDateRangePicker(
    context: context,
    initialDateRange: DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 1)),
    ),
    firstDate: DateTime.now(),
    lastDate: DateTime(2101),
  );

  // If a range is picked, update state
  if (pickedDateRange != null) {
    setState(() {
      _selectedDate1 = null; // Clear single date selection
      _selectedDateRange = pickedDateRange;
    });

    // Prompt for time if selecting a single date
    await _selectTime(context);
  } else {
    // Show single date picker if no range is selected
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate1 = pickedDate;
        _selectedDateRange = null; // Clear date range selection
      });

      // Prompt for time if selecting a single date
      await _selectTime(context);
    }
  }

  var pickUpLocation =
      Provider.of<AppInfo>(context, listen: false).pickUpLocation;
  var dropOffDestinationLocation =
      Provider.of<AppInfo>(context, listen: false).dropOffLocation;

addAdvanceBooking(
  widget.name,
  pickUpLocation!.placeName!, // Assert that placeName is not null
  dropOffDestinationLocation!.placeName!, // Assert that placeName is not null
  pickUpLocation.latitudePosition!, // Assert that latitudePosition is not null
  pickUpLocation.longitudePosition!, // Assert that longitudePosition is not null
  dropOffDestinationLocation.latitudePosition!, // Assert that latitudePosition is not null
  dropOffDestinationLocation.longitudePosition!, // Assert that longitudePosition is not null
  _selectedDateRange != null ? _selectedDateRange!.start : _selectedDate1!, 
  _selectedTime1 != null ? _selectedTime1!.format(context) : '',
  _selectedDateRange != null ? _selectedDateRange!.end : _selectedDate1!,
  widget.phone,
);

  // Show the review dialog with updated details
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF2E3192),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
      child: const Text(
        'Review Your Details!',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ),
              const SizedBox(height: 20),
              Text(
                  _selectedDateRange != null
                      ? "${_selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1}  Day Service"
                      : "1 Day Service",
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 10),
              // Display the selected date range or single date in the desired format
 Text(
  _selectedDateRange != null
      ? "${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}${_selectedTime1 != null ? ' at ${_selectedTime1!.format(context)}' : ''}"
      : "${DateFormat.yMMMd().format(_selectedDate1!)}${_selectedTime1 != null ? ' at ${_selectedTime1!.format(context)}' : ''}",
  style: const TextStyle(color: Colors.white, fontSize: 12),
),

              const Divider(),
              Text(pickUpLocation.placeName!,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 10),
              // Buttons to navigate or book
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Back button
                  Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: Colors.grey,
                         shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Rounded borders
      ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Book button
                  Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: Colors.green,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Your Service Ride has posted!',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 16)),
                                    Container(
                                      width: 150,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const HomePage()));
                                        },
                                        style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5), // Set border radius to 5
      ),
    ),
                                        child: const Text(
                                          'Back',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: Colors.green,
                         shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Rounded borders
      ),
                      ),
                      child: const Text(
                        'Book',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _selectTime(BuildContext context) async {
  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (pickedTime != null && pickedTime != _selectedTime1) {
    setState(() {
      _selectedTime1 = pickedTime;
    });
  }
}

}
