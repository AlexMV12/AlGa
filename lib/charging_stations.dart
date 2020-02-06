import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingStations{
  ChargingStations(GeoPoint pos, int speed, double price) {
    this.pos = pos;
    this.speed = speed;
    this.price = price;
  }

  GeoPoint pos;
  int speed;
  double price;
}