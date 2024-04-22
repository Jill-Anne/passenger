import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:passenger/pages/search_destination%20_page.dart';

import 'time_screen.dart';

void main() => runApp(BookingScreen());

class BookingScreen extends StatelessWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BookingHomePage(title: 'Booking Screen'),
    );
  }
}

class BookingHomePage extends StatefulWidget {
  final String title;

  const BookingHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<BookingHomePage> createState() => _BookingHomePageState();
}

class _BookingHomePageState extends State<BookingHomePage> {
  late List<DateTime?> _dialogCalendarPickerValue;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _dialogCalendarPickerValue = [];
    _startDate = DateTime.now();
    _endDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => SearchDestinationPage(),
            ));
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 375,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _buildCalendarDialogButton(),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(width: 16), // Add left spacing
                ElevatedButton(
                  onPressed: () {
                    // Handle Cancel button press
                    print('CANCEL button pressed');
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20), // Add horizontal padding
                    child: Text('CANCEL'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _startDate != _endDate
                      ? () {
                          // Handle Next button press
                          print('NEXT button pressed');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TimeScreen(
                                  startDate: _startDate, endDate: _endDate),
                            ),
                          );
                        }
                      : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20), // Add horizontal padding
                    child: Text('NEXT'),
                  ),
                ),
                SizedBox(width: 16), // Add right spacing
              ],
            ),
          ],
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
    return CalendarDatePicker2(
      config: config,
      value: _dialogCalendarPickerValue,
      onValueChanged: (values) {
        if (values != null && values.length == 2) {
          setState(() {
            _dialogCalendarPickerValue = values;
            _startDate = values[0]!;
            _endDate = values[1]!;
          });
        }
      },
    );
  }
}
