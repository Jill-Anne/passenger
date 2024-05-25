import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/pages/home_page.dart';
import 'package:passenger/services/add_advancebooking.dart';
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back)),
              ),
              Image.asset(
                'assets/images/Capture2.PNG',
              ),
              Image.asset(
                'assets/images/Capture3.PNG',
              ),
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

  DateTime? _selectedDate1;
  DateTimeRange? _selectedDateRange;
  TimeOfDay? _selectedTime1;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDateRange != null) {
      setState(() {
        _selectedDate1 = pickedDateRange.start;
        _selectedDateRange = pickedDateRange;
      });

      // Assuming you want to pick a time for the start date
      _selectTime(context).whenComplete(() {
        var pickUpLocation =
            Provider.of<AppInfo>(context, listen: false).pickUpLocation;
        var dropOffDestinationLocation =
            Provider.of<AppInfo>(context, listen: false).dropOffLocation;

        addAdvanceBooking(
          widget.name,
          pickUpLocation!.placeName,
          dropOffDestinationLocation!.placeName,
          pickUpLocation.latitudePosition,
          pickUpLocation.longitudePosition,
          dropOffDestinationLocation.latitudePosition,
          dropOffDestinationLocation.longitudePosition,
          _selectedDateRange!.start,
          _selectedTime1!.format(context),
          _selectedDateRange!.end,
          widget.phone,
        );

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
                    const Text('Review Your Details!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16)),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                        "${pickedDateRange.end.difference(pickedDateRange.start).inDays} Day Service",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(DateFormat.yMMMd().add_jm().format(_selectedDate1!),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                    const Divider(),
                    Text(pickUpLocation.placeName!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical:
                                  10), // Adjusted margin for better spacing
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              backgroundColor: Colors
                                  .grey, // Use the color from your reusable widget
                            ),
                            child: const Text(
                              'Back', // Custom text for the booking action
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical:
                                  10), // Adjusted margin for better spacing
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
                                          const Text(
                                              'Your Service Ride has posted!',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 16)),
                                          Container(
                                            width: 150,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical:
                                                    10), // Adjusted margin for better spacing
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                                backgroundColor: Colors
                                                    .grey, // Use the color from your reusable widget
                                              ),
                                              child: const Text(
                                                'Back', // Custom text for the booking action
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
                                    ),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              backgroundColor: Colors
                                  .green, // Use the color from your reusable widget
                            ),
                            child: const Text(
                              'Book', // Custom text for the booking action
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
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    }
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
