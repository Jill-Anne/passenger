import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String> addAdvanceBooking(
  String name, 
  String from, 
  String to, 
  double fromlat, 
  double fromlng, 
  double tolat, 
  double tolng, 
  DateTime date, 
  String time, 
  DateTime dateto, 
  String mynum
) async {
  final docUser = FirebaseFirestore.instance.collection('Advance Bookings').doc();

  // Generate the list of dates between the start and end date
  List<Map<String, dynamic>> dateList = [];
  DateTime tempDate = date;
  
  // Loop through each date between 'date' and 'dateto'
  while (!tempDate.isAfter(dateto)) {
    dateList.add({
      'date': Timestamp.fromDate(tempDate),
      'status': 'active',  // Default to 'active' status for each date
    });
    tempDate = tempDate.add(Duration(days: 1));
  }

  // Original booking details along with date list
  final json = {
    'mynum': mynum,
    'name': name,
    'from': from,
    'to': to,
    'fromlat': fromlat,
    'fromlng': fromlng,
    'tolat': tolat,
    'tolng': tolng,
    'date': Timestamp.fromDate(date),
    'dateto': Timestamp.fromDate(dateto),
    'time': time,
    'postedAt': Timestamp.fromDate(DateTime.now()),  // Ensure consistent timestamp format
    'id': docUser.id,
    'uid': FirebaseAuth.instance.currentUser!.uid,
    'day': DateTime.now().day,
    'month': DateTime.now().month,
    'year': DateTime.now().year,
    'status': 'Pending',
    'drivername': '',
    'driverlastName': '',
    'driverid': '',
    'driverbodynumber': '',
    'phoneNumber': '',
    'reason': '',
    'dates': dateList,  // Add the list of dates with their statuses
  };

  await docUser.set(json);

  return docUser.id;
}
