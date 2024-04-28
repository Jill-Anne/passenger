import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

import 'search_destination _page.dart';

class TimeScreen extends StatefulWidget {
  

  const TimeScreen({Key? key,})
      : super(key: key);

  @override
  _TimeScreenState createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> {
  late TimeOfDay _selectedTime;
  

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Time'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Time',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Container(
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
                  _buildTimePickerSpinner(),
                  SizedBox(height: 20),
                ],
              ),
            ),
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
                    _showConfirmationDialog(context);
                  },
                  child: Text('BOOK'),
                ),
              ],
            ),
          ],
        ),
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

  void _showConfirmationDialog(BuildContext context) {
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
                // Handle booking action
                print('Booking confirmed');
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => SearchDestinationPage(),
                ));
              },
              child: Text('BOOK'),
            ),
          ],
        );
      },
    );
  }
}