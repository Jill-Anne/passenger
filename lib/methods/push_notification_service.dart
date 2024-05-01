import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/widgets/state_management.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  static sendNotificationToSelectedDriver(
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
    Map<String, String> titleBodyNotificationMap;
    Map<String, String> dataMapNotification;

    if (hasDates) {
      titleBodyNotificationMap = {
        "title": "ADVANCE TRIP REQUEST from $userName",
        "body": "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress \nStart Date: ${startDate.toString()} \nEnd Date: ${endDate.toString()} \nTrip Time: $tripTime",
      };
      
      dataMapNotification = {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done",
        "tripID": tripID,
        "tripStartDate": startDate.toString(),
        "tripEndDate": endDate.toString(),
      };
    } else {
      titleBodyNotificationMap = {
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
    Map<String, dynamic> bodyNotificationMap = {
      "notification": titleBodyNotificationMap,
      "data": dataMapNotification,
      "priority": "high",
      "to": deviceToken,
    };

    try {
      var response = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": serverKeyFCM,
        },
        body: jsonEncode(bodyNotificationMap),
      );

      print('FCM request sent. Status code: ${response.statusCode}');
      print('FCM response body: ${response.body}');

      if (response.statusCode != 200) {
        print('Error sending FCM notification. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }
}
