import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Recharge{
  String id;
  Timestamp timestamp;
  double cashSpent;
  double kwRecharged;

  Recharge(this.id, this.timestamp, this.cashSpent, this.kwRecharged);
}