import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHandler {
  final BuildContext context;

  NotificationHandler(this.context);

  Future<void> handleNotification(RemoteMessage message) async {
    // Extract data from the notification
    final String? status = message.data['status'];
    final String? tripID = message.data['tripID'];

    print('Received notification with data:');
    print('Status: $status');
    print('Trip ID: $tripID');

    if (status == 'cancelled') {
      print('Trip cancelled notification received.');

      try {
        await _showCancellationDialog(tripID);
      } catch (e, stackTrace) {
        print('Error showing cancellation dialog: $e');
        print('Stack trace: $stackTrace');
      }
    } else {
      print('No action for this notification status.');
    }
  }

Future<void> _showCancellationDialog(String? tripID) async {
  print('Preparing to show cancellation dialog.');

  final result = await showDialog<int>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Container(
          color: const Color.fromARGB(255, 1, 42, 123), // Deep Blue Background
          padding: EdgeInsets.all(16.0),
          child: Center( // Center the title text
            child: Text(
              'Trip Canceled',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        content: Container(
          width: double.maxFinite, // Make the content full width
          child: Center( // Center the content text
            child: Text(
              'Your trip request was canceled because it’s outside our service area.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              textAlign: TextAlign.center, // Center align the text
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, 
              backgroundColor: Colors.red, // Button color
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(context).pop(1); // Return 1 to indicate 'OK' pressed
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    },
  );

  print('Dialog result: $result');
}

}
