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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: new SingleChildScrollView(
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
                padding: EdgeInsets.all(8.0),
                child: Form(
                  key: _newCarForm,
                  child: newCarForm(),
                )),
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
                      Navigator.pop(context); // Pop the "SignIn" route
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => HomePage()),
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
        )));
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
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Car'),
      keyboardType: TextInputType.visiblePassword,
      validator: (String value) {
        if (value.isEmpty || value.length < 2 || value.length > 15) {
          return 'Enter a valid car.';
        }
        return null;
      },
      onSaved: (String val) {
        _newCar = val;
      },
    );
  }

  void createRecord(var _userUid, var _name, var _car) async {
    await Firestore.instance.collection("users").document(_userUid).setData({
      'name': _name,
      'car': _car,
    });
  }

  // Example code for registration.
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
