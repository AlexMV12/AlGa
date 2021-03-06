import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'package:AlGa/charging_stations.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:background_locator/background_locator.dart';
import 'package:geolocator/geolocator.dart';
import 'main.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
    'AlGa', 'AlGa', 'AlGa', icon: 'app_icon',
    importance: Importance.Max, priority: Priority.High);
var iOSPlatformChannelSpecifics = IOSNotificationDetails();
var platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

class RechargeManager extends StatelessWidget {
  static ChargingStations selectedStation;
  final GlobalKey<FormState> _currentBatteryForm = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var _currentBatteryPercentage;
    debugPrint("building recharge manager...");
    return Scaffold(
        appBar: AppBar(
          title: Text("AlGa"),
        ),
        body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Please, insert the current charge percentage of your car's battery."
                  "\nI will notify you when the car is ready.",
                  style: TextStyle(fontSize: 16),
                ),
                Form(
                    key: _currentBatteryForm,
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Current battery (%)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        var parsedValue = double.parse(value);
                        if (parsedValue < 1 || parsedValue > 99) {
                          return 'Battery should be a value\nbetween 1 and 99';
                        }
                        return null;
                      },
                      onSaved: (String value) {
                        var parsedValue = double.parse(value);
                        _currentBatteryPercentage = parsedValue / 100;
                      },
                    )),
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    if (_currentBatteryForm.currentState.validate()) {
                      _currentBatteryForm.currentState.save();
                      _showNotificationChargeCompleted(
                          selectedStation, _currentBatteryPercentage);
                      Navigator.pop(context);
                    }
                  },
                )
              ],
            )));
  }

  static const String _isolateName = "LocatorIsolate";

  static Future<void> startRechargeMonitor(ChargingStations station) async {
    // If Location is not enabled, don't do anything.
    bool serviceStatus = await Geolocator().isLocationServiceEnabled();
    if (!serviceStatus) return;

    ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);

    selectedStation = station;
    var stationPosition = station.pos;

    port.listen((dynamic data) {
      var distance = calculateDistance(data.latitude, data.longitude,
          stationPosition.latitude, stationPosition.longitude);
      if (distance < 0.2) {
        stopLocationService();
        _showNotificationStationReached();
      }
    });

    startLocationService();
  }

  static void callback(LocationDto locationDto) async {
    final SendPort send = IsolateNameServer.lookupPortByName(_isolateName);
    send?.send(locationDto);
  }

  static Future<void> startLocationService() async {
    await BackgroundLocator.initialize();
    BackgroundLocator.registerLocationUpdate(
      callback,
      settings: LocationSettings(
          notificationTitle: "AlGa is tracking location.",
          notificationMsg: "This is needed due to Android limitations.",
          wakeLockTime: 60,
          autoStop: false,
          interval: 5),
    );
  }

  static void stopLocationService() {
    IsolateNameServer.removePortNameMapping(_isolateName);
    BackgroundLocator.unRegisterLocationUpdate();
  }
}

double calculateDistance(
    double initialLat, double initialLong, double finalLat, double finalLong) {
  int R = 6371;
  double dLat = toRadians(finalLat - initialLat);
  double dLon = toRadians(finalLong - initialLong);
  initialLat = toRadians(initialLat);
  finalLat = toRadians(finalLat);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(initialLat) * cos(finalLat);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double toRadians(double deg) {
  return deg * pi / 180.0;
}

Future _showNotificationChargeCompleted(
    ChargingStations station, double currentBatteryPercentage) async {
  // _rechargeSpeed is in Kw/h.
  // _userCarBattery is in Kw.
  var _rechargeSpeed = station.speed;
  var user = await _auth.currentUser();
  var _userCarBattery;

  await Firestore.instance
      .collection("users")
      .document(user.uid)
      .get()
      .then((DocumentSnapshot ds) {
    _userCarBattery = ds["car_battery"];
  });

  print("Recharge speed: $_rechargeSpeed");
  print("Current battery percentage: $currentBatteryPercentage");
  print("User car battery: $_userCarBattery");

  var timeRequestedForCharge =
      (_userCarBattery * (1 - currentBatteryPercentage)) / _rechargeSpeed;
  timeRequestedForCharge = timeRequestedForCharge * 60;
  print("Time requested for charge: $timeRequestedForCharge");
  timeRequestedForCharge = timeRequestedForCharge.toInt();

  print("Time requested for charge: $timeRequestedForCharge");

  var now = new DateTime.now();
  var estimatedEnd = now.add(new Duration(minutes: timeRequestedForCharge));

  print(estimatedEnd);

  await flutterLocalNotificationsPlugin.schedule(
      0,
      'Recharge terminated!',
      'Your car is fully charged and ready to go.',
      estimatedEnd,
      platformChannelSpecifics);

  await Firestore.instance
      .collection("recharges")
      .document(user.uid)
      .collection("0")
      .document()
      .setData({
    'timestamp': estimatedEnd,
    'cash_spent': double.parse(
        ((_userCarBattery * (1 - currentBatteryPercentage)) * station.price)
            .toStringAsFixed(2)),
    'kw_recharged': double.parse(
        (_userCarBattery * (1 - currentBatteryPercentage)).toStringAsFixed(2))
  });
}

Future _showNotificationStationReached() async {
  await flutterLocalNotificationsPlugin.show(
    0,
    'Charging station reached',
    'To start the recharge, click on this notification.',
    platformChannelSpecifics,
    payload: 'station_reached',
  );
}
