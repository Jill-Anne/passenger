import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
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

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));

        cMethods.displaySnackBar(
            "Your advance booking has been posted!", context);
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
