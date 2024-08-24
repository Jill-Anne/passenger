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
          title: Text('Trip Cancelled'),
          content: Text('Your trip with ID $tripID has been cancelled by the driver.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(1); // Return 1 to indicate 'OK' pressed
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    print('Dialog result: $result');
  }
}
