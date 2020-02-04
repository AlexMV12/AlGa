// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AlGa/home_page.dart';
import './register_page.dart';
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
          // get the Provider, and call the getUser method
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

//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Check User Screen',
//      home: MyHomePage(title: 'AlGa'),
//    );
//  }
//}
//
//class MyHomePage extends StatefulWidget {
//  MyHomePage({Key key, this.title}) : super(key: key);
//
//  final String title;
//
//  @override
//  _MyHomePageState createState() => _MyHomePageState();
//}
//
//class _MyHomePageState extends State<MyHomePage> {
//  FirebaseUser user;
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text(widget.title),
//      ),
//      body: Column(
//        crossAxisAlignment: CrossAxisAlignment.start,
//        children: <Widget>[
//          Container(
//            child: RaisedButton(
//              child: const Text('Test registration'),
//              onPressed: () => _pushPage(context, RegisterPage()),
//            ),
//            padding: const EdgeInsets.all(16),
//            alignment: Alignment.center,
//          ),
//          Container(
//            child: RaisedButton(
//              child: const Text('Test SignIn/SignOut'),
//              onPressed: () => _pushPage(context, SignInPage()),
//            ),
//            padding: const EdgeInsets.all(16),
//            alignment: Alignment.center,
//          ),
//        ],
//      ),
//    );
//  }
//
//  void _pushPage(BuildContext context, Widget page) {
//    Navigator.of(context).push(
//      MaterialPageRoute<void>(builder: (_) => page),
//    );
//  }
//}