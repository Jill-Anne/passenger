import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:passenger/appInfo/app_info.dart';
import 'package:passenger/global/global_var.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  static sendNotificationToSelectedDriver(String deviceToken, BuildContext context, String tripID) async {
    String dropOffDestinationAddress = Provider.of<AppInfo>(context, listen: false).dropOffLocation!.placeName.toString();
    String pickUpAddress = Provider.of<AppInfo>(context, listen: false).pickUpLocation!.placeName.toString();

    // Debug prints to verify the addresses
    print('DropOff Destination Address: $dropOffDestinationAddress');
    print('PickUp Address: $pickUpAddress');

    Map<String, String> headerNotificationMap = {
      "Content-Type": "application/json",
      "Authorization": serverKeyFCM,
    };

    Map titleBodyNotificationMap = {
      "title": "NEW TRIP REQUEST from $userName",
      "body": "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress",
    };

    Map dataMapNotification = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "tripID": tripID,
    };

    Map bodyNotificationMap = {
      "notification": titleBodyNotificationMap,
      "data": dataMapNotification,
      "priority": "high",
      "to": deviceToken,
    };

    // Debug print to verify the notification payload
    print('Sending Notification with payload: ${jsonEncode(bodyNotificationMap)}');

    var response = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotificationMap,
      body: jsonEncode(bodyNotificationMap),
    );

    // Debug prints to log the response from the FCM server
    print('FCM request sent. Status code: ${response.statusCode}');
    print('FCM response body: ${response.body}');

    if (response.statusCode != 200) {
      print('Error sending FCM notification. Status code: ${response.statusCode}');
    }
  }
}
