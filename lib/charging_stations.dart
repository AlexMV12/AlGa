import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingStations{
  GeoPoint pos;
  int speed;
  double price;
  double distance = 0.0;
  bool available;

  ChargingStations(GeoPoint pos, int speed, double price, bool available) {
    this.pos = pos;
    this.speed = speed;
    this.price = price;
    this.available = available;
  }
}