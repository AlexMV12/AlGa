import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingStations{
  GeoPoint pos;
  int speed;
  double price;
  double distance = 0.0;

  ChargingStations(GeoPoint pos, int speed, double price) {
    this.pos = pos;
    this.speed = speed;
    this.price = price;
  }
}