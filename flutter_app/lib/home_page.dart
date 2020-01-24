import 'package:flutter/material.dart';
import 'package:flutter_app/auth_service.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
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
      body: Center(
          child: Text('Home Page Flutter Firebase  Content'),
      ),
    );
  }
}