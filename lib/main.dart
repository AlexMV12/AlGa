// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:AlGa/recharge_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AlGa/home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './signin_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'AlGa',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder(
          // Check two things.
          // The first is the notification part: it's necessary to put it here
          // in order to catch the times in which the app is launched
          // clicking a notification.
          // The second is for the cases on normal launches: we check if the
          // user is already logged in or not.

          future: _auth.currentUser(),
          builder: (context, AsyncSnapshot snapshot) {

            // Initialize notifcation settings
            var initializationSettingsAndroid =
                AndroidInitializationSettings('app_icon');
            var initializationSettingsIOS = IOSInitializationSettings();
            var initializationSettings = InitializationSettings(
                initializationSettingsAndroid, initializationSettingsIOS);
            flutterLocalNotificationsPlugin.initialize(initializationSettings,
                onSelectNotification: (String payload) async {
              if (payload != null) {
                debugPrint('notification payload: ' + payload);
              }

              // If a station is reached, a "station reached" notification
              // is sent. Clicking it, we start the recharge manager.
              if (payload == "station_reached") {
                debugPrint("pushing recharge manager...");
                Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => RechargeManager()));
              }
            });

            // This is used in the case of a normal launch.
            // If the user is authenticated, launch the HomePage.
            // Otherwise, launch the SignIn Page.
            if (snapshot.connectionState == ConnectionState.done) {
              return snapshot.hasData ? HomePage() : SignInPage();
            } else {
              return Container(color: Colors.white);
            }
          },
        ));
  }
}
