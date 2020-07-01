// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'home_page.dart';
import 'main.dart';
import 'register_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignInPage extends StatefulWidget {
  final String title = 'AlGa';
  @override
  State<StatefulWidget> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final GlobalKey<FormState> _emailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordForm = GlobalKey<FormState>();

  var _email;
  var _password;

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
            Container(
              child: Text('Sign in with email and password'),
              padding: EdgeInsets.all(16.0),
              alignment: Alignment.center,
            ),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Form(key: _emailForm, child: emailForm())),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Form(key: _passwordForm, child: passwordForm())),
            Padding(
              padding: EdgeInsets.all(8.0),
            ),
            Builder(builder: (BuildContext context) {
              // Builder wrapper is necessary to use the SnackBar
              return RaisedButton(
                onPressed: () async {
                  if (_emailForm.currentState.validate() &&
                      _passwordForm.currentState.validate()) {
                    _emailForm.currentState.save();
                    _passwordForm.currentState.save();

                    var success = _signInWithEmailAndPassword();

                    success.then((value) {
                      if (value) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(builder: (_) => MyApp()),
                        );
                      } else {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text("Sign in failed, try again"),
                        ));
                      }
                    });
                  }
                },
                child: const Text('Sign in'),
              );
            }),
            Padding(
              padding: EdgeInsets.all(8.0),
            ),
            Divider(
              thickness: 2,
            ),
            Container(
              child: const Text('Register with email and password'),
              padding: const EdgeInsets.all(16.0),
            ),
            RaisedButton(
                child: const Text("Register"),
                onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => RegisterPage()),
                    )),
          ],
        )));
  }

  Widget emailForm() {
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
        _email = val;
      },
    );
  }

  Widget passwordForm() {
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
        _password = val;
      },
    );
  }

  Future<bool> _signInWithEmailAndPassword() async {
    try {
      final FirebaseUser user = (await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      ))
          .user;
      if (user != null) {
        return true;
      } else
        return false;
    } catch (PlatformException) {
      return false;
    }
  }
}

//class _AnonymouslySignInSection extends StatefulWidget {
//  @override
//  State<StatefulWidget> createState() => _AnonymouslySignInSectionState();
//}
//
//class _AnonymouslySignInSectionState extends State<_AnonymouslySignInSection> {
//  bool _success;
//  String _userID;
//  @override
//  Widget build(BuildContext context) {
//    return Column(
//      crossAxisAlignment: CrossAxisAlignment.start,
//      children: <Widget>[
//        Container(
//          child: const Text('Test sign in anonymously'),
//          padding: const EdgeInsets.all(16),
//          alignment: Alignment.center,
//        ),
//        Container(
//          padding: const EdgeInsets.symmetric(vertical: 16.0),
//          alignment: Alignment.center,
//          child: RaisedButton(
//            onPressed: () async {
//              _signInAnonymously();
//            },
//            child: const Text('Sign in anonymously'),
//          ),
//        ),
//        Container(
//          alignment: Alignment.center,
//          padding: const EdgeInsets.symmetric(horizontal: 16),
//          child: Text(
//            _success == null
//                ? ''
//                : (_success
//                ? 'Successfully signed in, uid: ' + _userID
//                : 'Sign in failed'),
//            style: TextStyle(color: Colors.red),
//          ),
//        )
//      ],
//    );
//  }
//
//  // Bugged for now
//  void _signInAnonymously() async {
//    final FirebaseUser user = (await _auth.signInAnonymously()).user;
//    assert(user != null);
//    assert(user.isAnonymous);
//    assert(!user.isEmailVerified);
//    assert(await user.getIdToken() != null);
//    if (Platform.isIOS) {
//      // Anonymous auth doesn't show up as a provider on iOS
//      assert(user.providerData.isEmpty);
//    } else if (Platform.isAndroid) {
//      // Anonymous auth does show up as a provider on Android
//      assert(user.providerData.length == 1);
//      assert(user.providerData[0].providerId == 'firebase');
//      assert(user.providerData[0].uid != null);
//      assert(user.providerData[0].displayName == null);
//      assert(user.providerData[0].photoUrl == null);
//      assert(user.providerData[0].email == null);
//    }
//
//    final FirebaseUser currentUser = await _auth.currentUser();
//    assert(user.uid == currentUser.uid);
//    if (currentUser != null) {
//      setState(() {
//        _success = true;
////        Navigator.of(context).push(
////          MaterialPageRoute<void>(builder: (_) => HomePage()),
////        );
//      });
//    } else {
//      _success = false;
//    }
//  }
//}
