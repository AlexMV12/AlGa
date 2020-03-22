import 'dart:io';
import 'package:AlGa/signin_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final GlobalKey<FormState> _newCarForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newEmailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _currPasswordForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newPasswordForm = GlobalKey<FormState>();

  var _newName;
  var _newCar;
  var _newEmail;
  var _currPassword;
  var _newPassword;

  var _userUid;
  var _userEmail;
  var _profileImageUrl;
  var _name = "novalue";
  var _car = "novalue";

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
            var circleAvatar;
            if (_profileImageUrl == 'none') {
              circleAvatar = CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey,
                child: Text("PIC", style: TextStyle(fontSize: 40)),
              );
            } else {
              circleAvatar = CircleAvatar(
                  radius: 90,
                  backgroundImage: NetworkImage(
                    _profileImageUrl,
                  ));
            }
            return SingleChildScrollView(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                circleAvatar,
                IconButton(
                  icon: Icon(Icons.photo_camera),
                  tooltip: 'Upload new profile pic',
                  onPressed: () => (updateProfilePic()),
                ),
                Divider(),
                Row(
                  children: <Widget>[
                    SizedBox(width: 50),
                    Icon(
                      Icons.account_box,
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        "Your name:",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Spacer(),
                    Text(
                      _name,
                      style: TextStyle(fontSize: 22),
                    ),
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
                    Spacer(
                      flex: 2,
                    ),
                  ],
                ),
                Divider(),
                Row(children: <Widget>[
                  SizedBox(width: 50),
                  Icon(
                    Icons.directions_car,
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Your selected\ncar:',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Spacer(),
                  Text(
                    _car,
                    style: TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Form(
                                key: _newCarForm,
                                child: newCarForm(),
                              ),
                              actions: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: () {
                                    if (_newCarForm.currentState.validate()) {
                                      _newCarForm.currentState.save();
                                      updateCar();
                                      Navigator.pop(context);
                                    }
                                  },
                                )
                              ],
                            );
                          })
                    },
                  ),
                  Spacer(),
                ]),
                Divider(),
                Row(children: <Widget>[
                  SizedBox(width: 50),
                  Icon(
                    Icons.email,
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Your email:',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Spacer(),
                  Text(
                    _userEmail,
                    style: TextStyle(fontSize: 12),
                  ),
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
                  Spacer(),
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
                                      deleteUser();
                                      _auth.signOut();
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute<void>(
                                            builder: (_) => SignInPage()),
                                      );
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

  Widget newCarForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Car'),
      validator: (String value) {
        if (value.isEmpty || value.length < 2 || value.length > 15) {
          return 'Your car should have between 2\nand 15 characters.';
        }
        return null;
      },
      onSaved: (String val) {
        _newCar = val;
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
      final FirebaseUser user = (await _auth.signInWithEmailAndPassword(
        email: _userEmail,
        password: _currPassword,
      ))
          .user;
      return true;
    } catch (PlatformException) {
      print("Error in logging in.");
      return false;
    }
  }

  Future<bool> getData() async {
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

    var profilePicLocation =
        FirebaseStorage.instance.ref().child("users_profilepics/" + _userUid);

    try {
      _profileImageUrl = await profilePicLocation.getDownloadURL();
    } on Exception catch (e) {
      _profileImageUrl = "none";
      print("Profile pic not found.");
    }
    // If an exception is been thrown in the console here, see
    // https://github.com/FirebaseExtended/flutterfire/issues/792

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
    var user = await _auth.currentUser();
    _userUid = user.uid;
    await Firestore.instance.collection("users").document(_userUid).updateData({
      'car': _newCar,
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
      } on Exception catch (e) {
        print("Profile pic not found, skipping deletion...");
      }

      await user.delete();
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: Account not deleted!"),
      ));
      return;
    }
  }
}
