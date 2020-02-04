import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

var _profileImageUrl;
var _name = "novalue";
var _car = "novalue";

Future <bool> getData() async {
  var user = await _auth.currentUser();
  var userUid = user.uid;
  await Firestore.instance
      .collection("users")
      .document(userUid)
      .get()
      .then((DocumentSnapshot ds) {
        _name = ds["name"];
        _car = ds["car"];
  });

  await FirebaseStorage.instance.ref().child(
      "users_profilepics/" + userUid
  ).getDownloadURL().then((val) => _profileImageUrl = val)
  .catchError((err) => _profileImageUrl = "none");

  return true;
}

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        var circleAvatar;

        if (_profileImageUrl == 'none') {
          circleAvatar = CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey,
            child: Text("PIC", style: TextStyle(fontSize: 40)),
        );} else {
            circleAvatar = CircleAvatar(
                radius: 80,
                backgroundImage: NetworkImage(
                  _profileImageUrl,
                )
            );}
        if (!snapshot.hasData) {
          // while data is loading:
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
        return Container(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 30,
              ),
              circleAvatar,
              Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    _name,
                    style: TextStyle(fontSize: 22),
                  )
              ),
              Text(
                'Your selected Car',
                style: TextStyle(fontSize: 15),
              ),
              Text(
                _car,
              ),
            ],
          ),
        );
      }
    });
  }
}