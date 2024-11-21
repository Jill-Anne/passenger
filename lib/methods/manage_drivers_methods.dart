import 'package:passenger/pages/online_nearby_drivers.dart';

import 'dart:async'; // Import for Timer functionality

class ManageDriversMethods {
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList = [];
  static Timer? _timer; // Timer to control periodic update
  static Function? updateMapCallback;  // Callback reference for updating the map

  // This method sets the callback that will be called to update the map
  // Method to set the callback to update the map
  static void setMapUpdateCallback(Function callback) {
    updateMapCallback = callback;
  }

  static void removeDriverFromList(String driverID) {
    int index = nearbyOnlineDriversList.indexWhere((driver) => driver.uidDriver == driverID);

    if (nearbyOnlineDriversList.isNotEmpty) {
      nearbyOnlineDriversList.removeAt(index);
    }
  }

  static void updateOnlineNearbyDriversLocation(OnlineNearbyDrivers nearbyOnlineDriverInformation) {
    int index = nearbyOnlineDriversList.indexWhere((driver) => driver.uidDriver == nearbyOnlineDriverInformation.uidDriver);

    if (index != -1) {
      nearbyOnlineDriversList[index].latDriver = nearbyOnlineDriverInformation.latDriver;
      nearbyOnlineDriversList[index].lngDriver = nearbyOnlineDriverInformation.lngDriver;
    }
  }

  // Method to start periodic updates
  static void startPeriodicUpdate() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      if (updateMapCallback != null) {
        updateMapCallback!();  // Call the callback to update the map
      }
    });
  }

  // Method to stop periodic updates when no longer needed
  static void stopPeriodicUpdate() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }
}
