import 'package:cloud_firestore/cloud_firestore.dart';

class Recharge{
  String id;
  Timestamp timestamp;
  double cashSpent;
  double kwRecharged;

  Recharge(this.id, this.timestamp, this.cashSpent, this.kwRecharged);
}