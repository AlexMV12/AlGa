import 'package:flutter/material.dart';
import 'package:flutter_app/auth_service.dart';
import 'package:flutter_app/loginPage.dart';
import 'package:flutter_app/home_page.dart';
import 'package:provider/provider.dart';

void main() => runApp(
  ChangeNotifierProvider<AuthService>(
    child: MyApp(),
    builder: (BuildContext context) {
      return AuthService();
    }
  )
);

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
        future: Provider.of<AuthService>(context).getUser(),
        // wait for the future to resolve and render the appropriate
        // widget for HomePage or LoginPage
        builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.hasData ? HomePage() : LoginPage();
          } else {
          return Container(color: Colors.white);
        }
        },
      )
    );
  }
}