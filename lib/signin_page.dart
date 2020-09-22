// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:uni_links/uni_links.dart';
import 'home_page.dart';
import 'main.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart';
import 'package:url_launcher/url_launcher.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignInPage extends StatefulWidget {
  final String title = 'AlGa';
  @override
  State<StatefulWidget> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final GlobalKey<FormState> _emailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordForm = GlobalKey<FormState>();

  StreamSubscription _subs;

  var _email;
  var _password;

  @override
  void initState() {
    _initDeepLinkListener();
    super.initState();
  }

  @override
  void dispose() {
    _disposeDeepLinkListener();
    super.dispose();
  }

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
            FlatButton(
              color: Colors.red,
              textColor: Colors.white,
              padding: EdgeInsets.all(8.0),
              splashColor: Colors.blueAccent,
              onPressed: () {
                onClickGitHubLoginButton();
              },
              child: Text(
                "Login with GitHub",
                style: TextStyle(fontSize: 15.0),
              ),
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

  void onClickGitHubLoginButton() async {
    const String url = "https://github.com/login/oauth/authorize" +
        "?client_id=" + "176ca01c449f94cdf298" +
        "&scope=public_repo%20read:user%20user:email";

    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
      );
    } else {
      print("CANNOT LAUNCH THIS URL!");
    }
  }

  void _initDeepLinkListener() async {
    _subs = getLinksStream().listen((String link) {
      _checkDeepLink(link);
    }, cancelOnError: true);
  }

  void _checkDeepLink(String link) {
    if (link != null) {
      String code = link.substring(link.indexOf(RegExp('code=')) + 5);
      loginWithGitHub(code)
          .then((firebaseUser) {
        print("LOGGED IN AS: " + firebaseUser.displayName);
      }).catchError((e) {
        print("LOGIN ERROR: " + e.toString());
      });
    }
  }

  void _disposeDeepLinkListener() {
    if (_subs != null) {
      _subs.cancel();
      _subs = null;
    }
  }

  Future<FirebaseUser> loginWithGitHub(String code) async {
    //ACCESS TOKEN REQUEST
    final response = await http.post(
      "https://github.com/login/oauth/access_token",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      // Keys are revoked, for safety
      body: jsonEncode(GitHubLoginRequest(
        clientId: "176ca01c449f94cdf298",
        clientSecret: "a51d4e5d075ebd68cbaef1776992525edf54cfa0",
        code: code,
      )),
    );

    GitHubLoginResponse loginResponse =
    GitHubLoginResponse.fromJson(json.decode(response.body));

    //FIREBASE STUFF
    final AuthCredential credential = GithubAuthProvider.getCredential(
      token: loginResponse.accessToken,
    );

    final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
    if (user != null) {
      await Firestore.instance.collection("users").document(user.uid).setData({
        'name': "NewUser",
        'car': "Custom",
        'car_range': 50.0,
        'car_battery': 50.0
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => MyApp()),
      );
    }

  }

}

//GITHUB REQUEST-RESPONSE MODELS
class GitHubLoginRequest {
  String clientId;
  String clientSecret;
  String code;

  GitHubLoginRequest({this.clientId, this.clientSecret, this.code});

  dynamic toJson() => {
    "client_id": clientId,
    "client_secret": clientSecret,
    "code": code,
  };
}

class GitHubLoginResponse {
  String accessToken;
  String tokenType;
  String scope;

  GitHubLoginResponse({this.accessToken, this.tokenType, this.scope});

  factory GitHubLoginResponse.fromJson(Map<String, dynamic> json) =>
      GitHubLoginResponse(
        accessToken: json["access_token"],
        tokenType: json["token_type"],
        scope: json["scope"],
      );
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
