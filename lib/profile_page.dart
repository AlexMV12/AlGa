import 'dart:io';
import 'car.dart';
import 'package:AlGa/signin_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class Profile extends StatefulWidget {
  final String title = 'Profile';
  @override
  State<StatefulWidget> createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  final GlobalKey<FormState> _newNameForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newEmailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _currPasswordForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newPasswordForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newUserCarBatteryForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newUserCarRangeForm = GlobalKey<FormState>();

  var _newName;
  var _newCar;
  var _newEmail;
  var _currPassword;
  var _newPassword;
  var _newUserCarBattery;
  var _newUserCarRange;

  var _userUid;
  var _userEmail;
  var _profileImageUrl;
  var _name;
  var _car;
  var _userCarBattery = 0.0;
  var _userCarRange = 0.0;

  List<Car> _cars = [];
  Future<bool> _isDataReady;

  @override
  void initState() {
    super.initState();
    _isDataReady = getData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _isDataReady,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            // while data is loading:
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            if (!snapshot.data) {
              print("Connection error! Can't show profile now.");
              return Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.error,
                        size: 100,
                      ),
                      Text(
                        "Check your internet connection.",
                        style: TextStyle(fontSize: 20),
                      )
                    ],
                  ));
            } else
              return SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 20,
                  ),
                  avatar(),
                  IconButton(
                    icon: Icon(Icons.photo_camera),
                    tooltip: 'Upload new profile pic',
                    onPressed: () => (updateProfilePic()),
                  ),
                  Divider(),
                  Row(
                    children: <Widget>[
                      SizedBox(width: 30),
                      Icon(
                        Icons.account_box,
                        size: 30,
                      ),
                      SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Name",
                            textAlign: TextAlign.right,
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _name,
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 19),
                          ),
                        ],
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: Form(
                                    key: _newNameForm,
                                    child: newNameForm(),
                                  ),
                                  actions: <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.check),
                                      onPressed: () {
                                        if (_newNameForm.currentState
                                            .validate()) {
                                          _newNameForm.currentState.save();
                                          updateName();
                                          Navigator.pop(context);
                                        }
                                      },
                                    )
                                  ],
                                );
                              })
                        },
                      ),
                      SizedBox(width: 30),
                    ],
                  ),
                  Divider(),
                  Row(children: <Widget>[
                    SizedBox(width: 30),
                    Icon(
                      Icons.directions_car,
                      size: 30,
                    ),
                    SizedBox(width: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Car",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey),
                        ),
                        new SizedBox(
                            // This solution is needed to give a
                            // fixed width to the box which will contain the
                            // selector.
                            width: MediaQuery.of(context).size.width - 130,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _car,
                              underline: Container(
                                height: 1,
                                color: Colors.transparent,
                              ),
                              onChanged: (String newValue) {
                                setState(() {
                                  _newCar = newValue;
                                  updateCar();
                                });
                              },
                              items: _cars
                                  .map((e) => e.name)
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                    value: value, child: Text(value));
                              }).toList(),
                            )),
                        Text(
                          "Battery (kWh)",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey),
                        ),
                        Row(children: <Widget>[
                          Text(
                            _userCarBattery.toString(),
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 19),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Form(
                                        key: _newUserCarBatteryForm,
                                        child: newUserCarBatteryForm(),
                                      ),
                                      actions: <Widget>[
                                        IconButton(
                                          icon: Icon(Icons.check),
                                          onPressed: () {
                                            if (_newUserCarBatteryForm
                                                .currentState
                                                .validate()) {
                                              _newUserCarBatteryForm
                                                  .currentState
                                                  .save();
                                              updateUserCarBattery();
                                              Navigator.pop(context);
                                            }
                                          },
                                        )
                                      ],
                                    );
                                  })
                            },
                          ),
                        ]),
                        Text(
                          "Range (Km)",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey),
                        ),
                        Row(children: <Widget>[
                          Text(
                            _userCarRange.toString(),
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 19),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Form(
                                        key: _newUserCarRangeForm,
                                        child: newUserCarRangeForm(),
                                      ),
                                      actions: <Widget>[
                                        IconButton(
                                          icon: Icon(Icons.check),
                                          onPressed: () {
                                            if (_newUserCarRangeForm
                                                .currentState
                                                .validate()) {
                                              _newUserCarRangeForm.currentState
                                                  .save();
                                              updateUserCarRange();
                                              Navigator.pop(context);
                                            }
                                          },
                                        )
                                      ],
                                    );
                                  })
                            },
                          ),
                        ]),
                      ],
                    ),
                    SizedBox(width: 30)
                  ]),
                  Divider(),
                  Row(children: <Widget>[
                    SizedBox(width: 30),
                    Icon(
                      Icons.email,
                      size: 30,
                    ),
                    SizedBox(width: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "E-Mail",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          _userEmail,
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                content: new SingleChildScrollView(
                                    child: new Form(
                                        key: _newEmailForm,
                                        child: Column(children: <Widget>[
                                          Text(
                                              "To perform this action, you have to provide also your password."),
                                          currPasswordForm(),
                                          newEmailForm()
                                        ]))),
                                actions: <Widget>[
                                  IconButton(
                                      icon: Icon(Icons.check),
                                      onPressed: () {
                                        if (_newEmailForm.currentState
                                            .validate()) {
                                          _newEmailForm.currentState.save();
                                          updateEmail();
                                          Navigator.pop(context);
                                        }
                                      })
                                ],
                              );
                            })
                      },
                    ),
                    SizedBox(width: 30)
                  ]),
                  Divider(),
                  FlatButton(
                    color: Colors.red,
                    textColor: Colors.white,
                    padding: EdgeInsets.all(8.0),
                    splashColor: Colors.blueAccent,
                    onPressed: () => {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: new SingleChildScrollView(
                                  child: new Form(
                                      key: _newPasswordForm,
                                      child: Column(children: <Widget>[
                                        Text(
                                            "Enter both your old and your new password."),
                                        currPasswordForm(),
                                        newPasswordForm()
                                      ]))),
                              actions: <Widget>[
                                IconButton(
                                    icon: Icon(Icons.check),
                                    onPressed: () {
                                      if (_newPasswordForm.currentState
                                          .validate()) {
                                        _newPasswordForm.currentState.save();
                                        updatePassword();
                                        Navigator.pop(context);
                                      }
                                    })
                              ],
                            );
                          })
                    },
                    child: Text(
                      "Edit Password",
                      style: TextStyle(fontSize: 15.0),
                    ),
                  ),
                  FlatButton(
                    color: Colors.red,
                    textColor: Colors.white,
                    padding: EdgeInsets.all(8.0),
                    splashColor: Colors.blueAccent,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: new SingleChildScrollView(
                                  child: new Form(
                                      key: _currPasswordForm,
                                      child: Column(children: <Widget>[
                                        Text("Enter your password."),
                                        currPasswordForm(),
                                      ]))),
                              actions: <Widget>[
                                IconButton(
                                    icon: Icon(Icons.check),
                                    onPressed: () {
                                      if (_currPasswordForm.currentState
                                          .validate()) {
                                        _currPasswordForm.currentState.save();
                                        Navigator.pop(context);
                                        deleteUser();
                                      }
                                    })
                              ],
                            );
                          });
                    },
                    child: Text(
                      "Delete account",
                      style: TextStyle(fontSize: 15.0),
                    ),
                  ),
                ],
              ));
          }
        });
  }

  Widget avatar() {
    if (_profileImageUrl == 'none') {
      return CircleAvatar(
        radius: 80,
        backgroundColor: Colors.grey,
        child: Text("PIC", style: TextStyle(fontSize: 40)),
      );
    } else {
      return CircleAvatar(
          radius: 90,
          backgroundImage: NetworkImage(
            _profileImageUrl,
          ));
    }
  }

  Widget newNameForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Name'),
      validator: (String value) {
        if (value.isEmpty || value.length < 2 || value.length > 15) {
          return 'Your name should have between 2\nand 15 characters.';
        }
        return null;
      },
      onSaved: (String val) {
        _newName = val;
      },
    );
  }

  Widget newUserCarBatteryForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Battery'),
      keyboardType: TextInputType.number,
      validator: (value) {
        try {
          var parsedValue = double.parse(value);
          if (parsedValue < 0 || parsedValue > 300) {
            return 'Battery should be a value\nbetween 0 and 300';
          }
        }
        catch (e) {
          return 'Battery should be a value\nbetween 0 and 300';
        }

        return null;
      },
      onSaved: (String value) {
        var parsed = double.parse(value);
        _newUserCarBattery = double.parse(parsed.toStringAsFixed(2));
      },
    );
  }

  Widget newUserCarRangeForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Range'),
      keyboardType: TextInputType.number,
      validator: (value) {
        try {
          var parsedValue = double.parse(value);
          if (parsedValue < 0 || parsedValue > 1000) {
            return 'Range should be a value\nbetween 0 and 1000';
          }
        }
        catch (e) {
          return 'Range should be a value\nbetween 0 and 1000';
        }

        return null;
      },
      onSaved: (String value) {
        var parsed = double.parse(value);
        _newUserCarRange = double.parse(parsed.toStringAsFixed(2));
      },
    );
  }

  Widget newEmailForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      validator: (String value) {
        if (!EmailValidator.validate(value)) {
          return 'Enter a valid email.';
        }
        return null;
      },
      onSaved: (String val) {
        _newEmail = val;
      },
    );
  }

  Widget currPasswordForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Current password'),
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      validator: (String value) {
        if (value.isEmpty || value.length < 6 || value.length > 40) {
          return 'Provide your current password.';
        }
        return null;
      },
      onSaved: (String val) {
        _currPassword = val;
      },
    );
  }

  Widget newPasswordForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'New password'),
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      validator: (String value) {
        if (value.isEmpty || value.length < 6 || value.length > 40) {
          return 'Enter a valid password.';
        }
        return null;
      },
      onSaved: (String val) {
        _newPassword = val;
      },
    );
  }

  Future<bool> _signInWithEmailAndPassword() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _userEmail,
        password: _currPassword,
      );
      return true;
    } catch (PlatformException) {
      print("Error in logging in.");
      return false;
    }
  }

  Future<bool> getData() async {
    // Try to fetch the data of users and available cars.
    // Return false in case of errors, true otherwise.
    var user = await _auth.currentUser();
    _userUid = user.uid;
    _userEmail = user.email;
    await Firestore.instance
        .collection("users")
        .document(_userUid)
        .get()
        .then((DocumentSnapshot ds) {
      _name = ds["name"];
      _car = ds["car"];
      _userCarRange = ds["car_range"];
      _userCarBattery = ds["car_battery"];
    });
//    await FirebaseStorage.instance
//        .ref()
//        .child("users_profilepics/" + _userUid)
//        .getDownloadURL()
//        .then((val) => _profileImageUrl = val)
//        .catchError((err) {
//          _profileImageUrl = "none";
//          print("Profile pic not found.");
//        });
    try {
      var profilePicLocation =
          FirebaseStorage.instance.ref().child("users_profilepics/" + _userUid);
      _profileImageUrl = await profilePicLocation.getDownloadURL();
    } catch (_) {
      _profileImageUrl = "none";
      print("Profile pic not found, skipping...");
    }
    // If an exception is been thrown in the console here, see
    // https://github.com/FirebaseExtended/flutterfire/issues/792

    if (_cars.length == 0) {
      final QuerySnapshot result =
          await Firestore.instance.collection('cars').getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      documents.forEach((data) {
        // Can't use data["range"] and data["battery"] directly
        // it hangs up
        // flutter firebase bug?
        var range = double.parse(data["range"].toString());
        var battery = double.parse(data["battery"].toString());
        _cars.add(Car(data["name"], range, battery));
      });
    }

    if (_cars.isEmpty || _name == null || _car == null) {
      return false;
    }
    return true;
  }

  updateProfilePic() async {
    File _image;

    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        _image = image;
      }
    });

    if (_image != null) {
      StorageReference storageReference =
          FirebaseStorage.instance.ref().child("users_profilepics/" + _userUid);
      StorageUploadTask uploadTask = storageReference.putFile(_image);
      await uploadTask.onComplete
          .catchError((err) => print("Image not uploaded"));
      print('File Uploaded');

      setState(() {
        _isDataReady = getData();
      });
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Pic updated!"),
      ));
    }
  }

  updateName() async {
    var user = await _auth.currentUser();
    _userUid = user.uid;
    await Firestore.instance.collection("users").document(_userUid).updateData({
      'name': _newName,
    }).catchError((err) {
      print(err);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: Name not updated!"),
      ));
      return;
    });

    setState(() {
      _isDataReady = getData();
    });
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Name updated!"),
    ));
  }

  updateCar() async {
    Car newCar = _cars.where((element) => element.name == _newCar).first;
    var user = await _auth.currentUser();
    _userUid = user.uid;
    await Firestore.instance.collection("users").document(_userUid).updateData({
      'car': newCar.name,
      'car_battery': newCar.battery,
      'car_range': newCar.range
    }).catchError((err) {
      print(err);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: Car not updated!"),
      ));
      return;
    });

    setState(() {
      _isDataReady = getData();
    });
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Car updated!"),
    ));
  }

  updateUserCarBattery() async {
    var user = await _auth.currentUser();
    _userUid = user.uid;
    await Firestore.instance.collection("users").document(_userUid).updateData({
      'car_battery': _newUserCarBattery,
    }).catchError((err) {
      print(err);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: Battery not updated!"),
      ));
      return;
    });

    setState(() {
      _isDataReady = getData();
    });
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Battery updated!"),
    ));
  }

  updateUserCarRange() async {
    var user = await _auth.currentUser();
    _userUid = user.uid;
    await Firestore.instance.collection("users").document(_userUid).updateData({
      'car_range': _newUserCarRange,
    }).catchError((err) {
      print(err);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: Car range not updated!"),
      ));
      return;
    });

    setState(() {
      _isDataReady = getData();
    });
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Car range updated!"),
    ));
  }

  updateEmail() async {
    if (await _signInWithEmailAndPassword()) {
      var user = await _auth.currentUser();
      await user.updateEmail(_newEmail).catchError((err) {
        print(err);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Error: Email not updated!"),
        ));
        return;
      });
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: Email not updated!"),
      ));
      return;
    }

    setState(() {
      _isDataReady = getData();
    });
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Email updated!"),
    ));
  }

  updatePassword() async {
    if (await _signInWithEmailAndPassword()) {
      var user = await _auth.currentUser();
      await user.updatePassword(_newPassword).catchError((err) {
        print(err);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Error: Password not updated!"),
        ));
        return;
      });
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: Password not updated!"),
      ));
      return;
    }

    setState(() {
      _isDataReady = getData();
    });
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Password updated!"),
    ));
  }

  deleteUser() async {
    if (await _signInWithEmailAndPassword()) {
      var user = await _auth.currentUser();

      await Firestore.instance.collection("users").document(_userUid).delete();

      var profilePicLocation =
          FirebaseStorage.instance.ref().child("users_profilepics/" + _userUid);

      try {
        await profilePicLocation.delete();
      } on Exception {
        print("Profile pic not found, skipping deletion...");
      }

      await user.delete();
      _auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => SignInPage()),
      );
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("The password is not correct. Try again."),
      ));
      return;
    }
  }
}
