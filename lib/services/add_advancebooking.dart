import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String> addAdvanceBooking(name, from, to, fromlat, fromlng, tolat, tolng,
    date, time, dateto, mynum) async {
  final docUser =
      FirebaseFirestore.instance.collection('Advance Bookings').doc();

  final json = {
    'mynum': mynum,
    'name': name,
    'from': from,
    'to': to,
    'fromlat': fromlat,
    'fromlng': fromlng,
    'tolat': tolat,
    'tolng': tolng,
    'date': date,
    'dateto': dateto,
    'time': time,
    'postedAt': DateTime.now(),
    'id': docUser.id,
    'uid': FirebaseAuth.instance.currentUser!.uid,
    'day': DateTime.now().day,
    'month': DateTime.now().month,
    'year': DateTime.now().year,
    'status': 'Pending',
    'drivername': '',
    'driverid': '',
    'driverbodynumber': '',
    'drivernumber': '',
    'reason': '',
  };

  await docUser.set(json);

  return docUser.id;
}
