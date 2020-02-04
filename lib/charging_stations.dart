import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChargingStations{
  var _pos;

  Future<void> getData() async {
    Firestore.instance
        .collection("Charging_stations")
        .document("eY12sQWkyATy9hnXiwtU")
        .get()
        .then((DocumentSnapshot ds) {
      _pos = ds["pos"];
    });
  }
}