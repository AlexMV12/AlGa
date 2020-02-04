// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

void createRecord(var _useruid, var _name, var _car) async {
  await Firestore.instance.collection("users")
      .document(_useruid)
      .setData({
    'name': _name,
    'car': _car,
  });
}

class RegisterPage extends StatefulWidget {
  final String title = 'Registration';
  @override
  State<StatefulWidget> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _carController = TextEditingController();
  bool _success;
  String _userEmail;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Please enter a valid email.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Please enter a valid password.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Please enter a valid username.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _carController,
              decoration: const InputDecoration(labelText: 'Car'),
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Please enter a valid car model.';
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
                    _register();
                  }
                },
                child: const Text('Submit'),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Text(_success == null
                  ? ''
                  : (_success
                  ? 'Successfully registered ' + _userEmail
                  : 'Registration failed')),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Example code for registration.
  void _register() async {
    try {
      final FirebaseUser user = (await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ))
          .user;
      if (user != null) {
        createRecord(user.uid, _usernameController.text, _carController.text);
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => HomePage()),
        );
      } else {
        _success = false;
      }
    }
    catch (PlatformException) {
      setState(() {
        _success = false;
      });
    }
  }
}