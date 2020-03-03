// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'register_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignInPage extends StatefulWidget {
  final String title = 'Sign In';
  @override
  State<StatefulWidget> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Builder(builder: (BuildContext context) {
        return ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            _EmailPasswordForm(),
            _Register(),
//            _AnonymouslySignInSection(),
          ],
        );
      }),
    );
  }
}


class _EmailPasswordForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<_EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _success;
  String _userEmail;
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: const Text('Sign in with email and password'),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
          ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (String value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: RaisedButton(
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  _signInWithEmailAndPassword();
                }
              },
              child: const Text('Submit'),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _success == null
                  ? ''
                  : (_success
                  ? 'Successfully signed in ' + _userEmail
                  : 'Sign in failed'),
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Example code of how to sign in with email and password.
  void _signInWithEmailAndPassword() async {
    try {
      final FirebaseUser user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ))
          .user;
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => HomePage()),
        );
      }
    }
    catch (PlatformException) {
      setState(() {
        _success = false;
      });
    }
  }
}


class _Register extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
        children: <Widget>[
          Container(
            child: const Text('Register with email and password'),
            padding: const EdgeInsets.all(16),
          ),
          Container(
            child: RaisedButton(
                child: const Text("Register"),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => RegisterPage()),
                )
            ),
          )
        ]);
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




