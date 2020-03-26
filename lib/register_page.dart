import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'package:email_validator/email_validator.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class RegisterPage extends StatefulWidget {
  final String title = 'Registration';
  @override
  State<StatefulWidget> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _newNameForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newCarForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newEmailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _newPasswordForm = GlobalKey<FormState>();

  var _newName;
  var _newCar;
  var _newEmail;
  var _newPassword;

  List<String> _cars = [];
  var _isDataReady;

  @override
  void initState() {
    super.initState();
    _isDataReady = getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: FutureBuilder<bool>(
            future: _isDataReady,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (!snapshot.hasData) {
                // while data is loading:
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                if (!snapshot.data) {
                  print("Connection error! Can't register now.");
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
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Form(
                            key: _newEmailForm,
                            child: newEmailForm(),
                          )),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Form(
                            key: _newNameForm,
                            child: newNameForm(),
                          )),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Form(
                            key: _newPasswordForm,
                            child: newPasswordForm(),
                          )),
                      Padding(
                          padding: EdgeInsets.all(8.0), child: newCarForm()),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                      ),
                      RaisedButton(
                        onPressed: () async {
                          if (_newEmailForm.currentState.validate() &&
                              _newPasswordForm.currentState.validate() &&
                              _newNameForm.currentState.validate() &&
                              _newCarForm.currentState.validate()) {
                            _newEmailForm.currentState.save();
                            _newPasswordForm.currentState.save();
                            _newNameForm.currentState.save();
                            _newCarForm.currentState.save();

                            var success = _register();

                            success.then((value) {
                              if (value) {
                                Navigator.pop(
                                    context); // Pop the "SignIn" route
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                      builder: (_) => HomePage()),
                                );
                              } else {
                                Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text("Registration failed"),
                                ));
                              }
                            });
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ));
              }
            }));
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

  Widget newPasswordForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Password'),
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      validator: (String value) {
        if (value.isEmpty || value.length < 6 || value.length > 40) {
          return 'Enter a valid password (length between 6 and 40 characters)';
        }
        return null;
      },
      onSaved: (String val) {
        _newPassword = val;
      },
    );
  }

  Widget newNameForm() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Username'),
      keyboardType: TextInputType.text,
      validator: (String value) {
        if (value.isEmpty || value.length < 2 || value.length > 25) {
          return 'Enter a valid username (length between 2 and 25 characters)';
        }
        return null;
      },
      onSaved: (String val) {
        _newName = val;
      },
    );
  }

  Widget newCarForm() {
    return Row(children: <Widget>[
      Text("Select your car:"),
      Spacer(),
      DropdownButton<String>(
        onChanged: (String newValue) {
          setState(() {
            _newCar = newValue;
          });
        },
        items: _cars.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
      Spacer()
    ]);
  }

  Future<bool> getData() async {
    // Try to fetch the list of available cars. Return false in case of errors,
    // true otherwise.
    if (_cars.length == 0) {
      await Firestore.instance
          .collection("cars")
          .getDocuments()
          .then((snapshot) {
        for (var car in snapshot.documents) {
          _cars.add(car["name"]);
        }
      });
    }
    if (_cars.isEmpty)
      return false;
    else
      return true;
  }

  void createRecord(var _userUid, var _name, var _car) async {
    await Firestore.instance.collection("users").document(_userUid).setData({
      'name': _name,
      'car': _car,
    });
  }

  Future<bool> _register() async {
    try {
      final FirebaseUser user = (await _auth.createUserWithEmailAndPassword(
        email: _newEmail,
        password: _newPassword,
      ))
          .user;
      if (user != null) {
        createRecord(user.uid, _newName, _newCar);
        return true;
      } else {
        return false;
      }
    } catch (PlatformException) {
      return false;
    }
  }
}
