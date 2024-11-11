import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/main.dart';
import 'package:passenger/methods/firebaseToken.dart';
import 'package:passenger/widgets/state_management.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PushNotificationService {
  static Future<void> sendNotificationToSelectedDriver(
      String deviceToken, BuildContext context, String tripID) async {
    // Get trip data from TripData provider
    TripData tripData = Provider.of<TripData>(context, listen: false);
    DateTime? startDate = tripData.startDate;
    DateTime? endDate = tripData.endDate;

    // Get trip time (if available)
    String tripTime = tripData.selectedTime.format(context);

    // Get pickup and drop-off addresses
    String dropOffDestinationAddress = Provider.of<AppInfo>(context, listen: false).dropOffLocation?.placeName ?? "Unknown Drop-off";
    String pickUpAddress = Provider.of<AppInfo>(context, listen: false).pickUpLocation?.placeName ?? "Unknown Pick-up";

    // Check if start date and end date are available
    bool hasDates = startDate != null && endDate != null;

    // Notification title and body
    Map<String, String> notificationMap;
    Map<String, String> dataMapNotification;

    if (hasDates) {
      notificationMap = {
        "title": "ADVANCE TRIP REQUEST from $userName",
        "body": "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress \nStart Date: ${DateFormat('MMM d, yyyy').format(startDate!)} \nEnd Date: ${DateFormat('MMM d, yyyy').format(endDate!)} \nTrip Time: $tripTime",
      };

      dataMapNotification = {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done",
        "tripID": tripID,
        "tripStartDate": DateFormat('MMM d, yyyy').format(startDate),
        "tripEndDate": DateFormat('MMM d, yyyy').format(endDate),
      };
    } else {
      notificationMap = {
        "title": "NEW TRIP REQUEST from $userName",
        "body": "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress",
      };

      dataMapNotification = {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done",
        "tripID": tripID,
      };
    }

    // Complete notification body
    Map<String, dynamic> messageMap = {
      "message": {
        "token": deviceToken,
        "notification": notificationMap,
        "data": dataMapNotification,
      }
    };

    print('Preparing to send FCM notification...');
    print('Device Token: $deviceToken');
    print('Notification Body: ${jsonEncode(messageMap)}');

    try {
      // Get FCM access token
      final String accessToken = await FirebaseAccessToken.getToken();
      print('Retrieved FCM access token: $accessToken');

      // Sending FCM notification
      var response = await http.post(
        Uri.parse("https://fcm.googleapis.com/v1/projects/capstone-ca5d5/messages:send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(messageMap),
      );

      print('FCM request sent.');
      print('Request URL: https://fcm.googleapis.com/v1/projects/capstone-ca5d5/messages:send');
      print('Request Headers: ${jsonEncode({
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      })}');
      print('Request Body: ${jsonEncode(messageMap)}');
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('FCM notification sent successfully.');
      } else {
        print('Error sending FCM notification. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }
}
