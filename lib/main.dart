// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AlGa/home_page.dart';
import './signin_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder(
          // check if an user is already logged in
          future: _auth.currentUser(),
          // wait for the future to resolve and render the appropriate
          // widget for HomePage or LoginPage
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return snapshot.hasData ? HomePage() : SignInPage();
            } else {
              return Container(color: Colors.white);
            }
          },
        )
    );
  }
}
