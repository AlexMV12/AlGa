import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final StorageReference storageReference = FirebaseStorage().ref().child(
    'gs://dima-project-alga.appspot.com/users_profilepics' + '/'
);


var _profileImageUrl;// = 'https://s14-eu5.startpage.com/cgi-bin/serveimage?url=https%3A%2F%2Fi.ytimg.com%2Fvi%2FXjkMMkfUQWA%2Fhqdefault.jpg&sp=3b1d4d4cbe35fbd0f12087a53ee33fbe&anticache=339340';
var _name = "novalue";
var _car = "novalue";

Future <bool> getData() async {
  var user = await _auth.currentUser();
  var userUid = user.uid;
  Firestore.instance
      .collection("users")
      .document(userUid)
      .get()
      .then((DocumentSnapshot ds) {
        _name = ds["name"];
        _car = ds["car"];
  });
  print("hello");
  var storage = FirebaseStorage.instance.ref().child(
      "users_profilepics/hx0i0SjHA1YFSFv2RODMiekSrae2"
  );

  _profileImageUrl = await storage.getDownloadURL();
  print("hello2");
//  return Future.delayed((Duration(seconds: 2)), () => true);
}
    

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 30,
          ),
          FutureBuilder<bool>(
            future: getData(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (!snapshot.hasData) {
              // while data is loading:
              return Center(
              child: CircularProgressIndicator(),
              );
              } else {
              return CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(
                    _profileImageUrl,
                  )
              );
            }
              }),
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
}