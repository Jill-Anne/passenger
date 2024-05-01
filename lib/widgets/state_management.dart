import 'package:flutter/material.dart';

class TripData with ChangeNotifier {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _selectedTime = TimeOfDay.now();

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  TimeOfDay get selectedTime => _selectedTime;

  void setTripData(
      DateTime? startDate, DateTime? endDate, TimeOfDay selectedTime) {
    _startDate = startDate;
    _endDate = endDate;
    _selectedTime = selectedTime;
    notifyListeners();
  }
}
