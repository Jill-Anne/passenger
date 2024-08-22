import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHandler extends StatefulWidget {
  @override
  _NotificationHandlerState createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(RemoteMessage message) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (mounted) {
        String status = message.data['status'] ?? '';
        String tripID = message.data['tripID'] ?? '';

        if (status == 'cancelled') {
          _showCancellationDialog(tripID);
        }
      }
    });
  }

  void _showCancellationDialog(String tripID) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // Remove any existing overlay entry to prevent multiple dialogs
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trip Cancelled',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'The trip with ID $tripID has been cancelled.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _overlayEntry
                            ?.remove(); // Safely remove the overlay entry
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Handler"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Waiting for notifications..."),
            ElevatedButton(
              onPressed: () {
                print('Simulating a message for testing dialog');
                _showCancellationDialog('TEST_TRIP_ID');
              },
              child: Text("Test Dialog"),
            ),
          ],
        ),
      ),
    );
  }
}
