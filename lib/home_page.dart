import 'package:flutter/material.dart';
import 'package:AlGa/auth_service.dart';
import 'package:AlGa/gmaps.dart';
import 'package:AlGa/profile_page.dart';
import 'package:provider/provider.dart';

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
          title: Text("Home Flutter Firebase"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Provider.of<AuthService>(context).logout();
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
            Icon(Icons.alarm),
            Gmaps(),
            Profile()
          ],
        ),
      ),
    );
  }
}