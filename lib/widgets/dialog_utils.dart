import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:passenger/widgets/state_management.dart';
import 'package:provider/provider.dart';

class DialogUtils {
 
  static late DateTime _startDate;
  static late DateTime _endDate;
  static late TimeOfDay _selectedTime;
  static List<DateTime?> _dialogCalendarPickerValue = []; // Initialize _dialogCalendarPickerValue as an empty list

// Define a callback function that takes a String and a String parameter
static void Function(String, String)? _dateTimeCallback;

// Method to set the callback function
static void setDateTimeCallback(void Function(String, String) callback) {
  _dateTimeCallback = callback;
}

  static Widget buildCalendarDialogButton(BuildContext context) {
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
        if (DateTime.now().year == 2021 && date.month == 1 && date.day == 25) {
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
                    _dialogCalendarPickerValue = values;
                    _startDate = values[0]!;
                    _endDate = values[1]!;
                  } else if (values != null && values.length == 1) {
                    _dialogCalendarPickerValue = values;
                    _startDate = values[0]!;
                    _endDate = values[0]!;
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
            child: _buildCalendarDialogButtons(context),
          ),
        ],
      ),
    );
  }

  static Widget _buildCalendarDialogButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _navigateToTimeSpinner(context, closeCalendarDialog: true);
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  static void showRideOptionsDialog(BuildContext context) {
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
                        return buildCalendarDialogButton(context);
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

  static void _navigateToTimeSpinner(BuildContext context,
      {required bool closeCalendarDialog}) {
    if (closeCalendarDialog) {
      Navigator.of(context).pop();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: buildTime(context),
        );
      },
    );
  }


  static Widget _buildTimePickerSpinner(BuildContext context) {
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
        _selectedTime = TimeOfDay.fromDateTime(time);
      },
    );
  }

  static Widget buildTime(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
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
          _buildTimePickerSpinner(context),
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
                      _startDate = DateTime.now();
                      _endDate = DateTime.now();
                      _dialogCalendarPickerValue = [];
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

static void _showConfirmationDialog(BuildContext context, DateTime startDate, DateTime endDate, {required bool closeTimeSpinnerDialog, required VoidCallback resetDatesCallback}) {
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
                  ? 'Selected Date: ${startDate.day}/${startDate.month}/${startDate.year}'
                  : 'Selected Date Range: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
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

              // Store data in shared state
              Provider.of<TripData>(context, listen: false).setTripData(startDate, endDate, _selectedTime);

              resetDatesCallback();
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
