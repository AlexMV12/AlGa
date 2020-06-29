import 'package:flutter/material.dart';

import 'package:AlGa/stats.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AlGa/gmaps.dart';
import 'package:AlGa/profile_page.dart';

import 'signin_page.dart';


final FirebaseAuth _auth = FirebaseAuth.instance;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return  DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("AlGa"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                _auth.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => SignInPage()),
                );
              },
              child: Text(
                "LOGOUT",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.blue,
          child: TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.info), text: "stats"),
              Tab(icon: Icon(Icons.local_gas_station), text: "stations"),
              Tab(icon: Icon(Icons.person), text: "profile"),
            ],
          ),
        ),
        body: TabBarView(
          physics: new NeverScrollableScrollPhysics(),
          children: <Widget>[
            StatsPage(),
            Gmaps(),
            Profile()
          ],
        ),
      ),
    );
  }
}