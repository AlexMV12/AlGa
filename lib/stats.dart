import 'package:AlGa/recharge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jiffy/jiffy.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class StatsPage extends StatefulWidget {
  @override
  StatsPageState createState() => new StatsPageState();
}

class StatsPageState extends State<StatsPage> {

  final GlobalKey<FormState> _newCashSpentForm = GlobalKey<FormState>();

  Future<bool> _isDataReady;
  List<Recharge> _recharges = [];

  List<String> _granularity = ["Year", "Month", "Week"];

  var _totalSpent;
  var _totalRecharged;
  var _meanPrice;
  var _selectedGranularity = "Week";

  var _newCashSpent;
  var _newKwRecharged;

  @override
  void initState() {
    super.initState();
    _isDataReady = getData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _isDataReady,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            // while data is loading:
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            if (!snapshot.data) {
              print("Connection error! Can't show profile now.");
              return Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.error,
                        size: 100,
                      ),
                      Text(
                        "Check your internet connection.",
                        style: TextStyle(fontSize: 20),
                      )
                    ],
                  ));
            } else {
              if (_recharges.length == 0)
                return Align(
                    alignment: Alignment.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.wb_sunny,
                          size: 100,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "No charges so far.",
                          style: TextStyle(fontSize: 20),
                        )
                      ],
                    ));
              else
                return SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Statistics",
                          style: TextStyle(fontSize: 20),
                        ),
                        new SizedBox(
                          // This solution is needed to give a
                          // fixed width to the box which will contain the
                          // selector.
                            width: 100,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedGranularity,
                              underline: Container(
                                height: 1,
                                color: Colors.transparent,
                              ),
                              onChanged: (String newValue) {
                                setState(() {
                                  _selectedGranularity = newValue;
                                  updateStatistics();
//                            updateCar();
                                });
                              },
                              items: _granularity
                                  .map<DropdownMenuItem<String>>((
                                  String value) {
                                return DropdownMenuItem<String>(
                                    value: value, child: Text(value));
                              }).toList(),
                            )),
                        Text("Cash spent: $_totalSpent €"),
                        Text("kW recharged: $_totalRecharged kW"),
                        Text("Mean price: $_meanPrice €"),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Recharges list",
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                            height: 400,
                            child: Scrollbar(
                                child: ListView.builder(
                                    itemCount: _recharges.length,
                                    itemBuilder: (BuildContext context,
                                        int index) {
                                      _recharges.sort((a, b) =>
                                          a.timestamp.compareTo(b.timestamp));
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 30, vertical: 5),
                                        child: Row(
                                          children: <Widget>[
                                            IconButton(
                                              icon: Icon(Icons.mode_edit),
                                              onPressed: () => {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        content: new SingleChildScrollView(
                                                            child: new Form(
                                                                key: _newCashSpentForm,
                                                                child: Column(children: <Widget>[
                                                                  Text(
                                                                      "You can fix the values of the recharge."),
                                                                  newCashSpentForm(_recharges[index]),
                                                                  newKwRechargedForm(_recharges[index]),
                                                                ]))),
                                                        actions: <Widget>[
                                                          IconButton(
                                                              icon: Icon(Icons.check),
                                                              onPressed: () {
                                                                if (_newCashSpentForm.currentState
                                                                    .validate()) {
                                                                  _newCashSpentForm.currentState.save();
                                                                  modifyRecharge(_recharges[index]);
                                                                  Navigator.pop(context);
                                                                }
                                                              })
                                                        ],
                                                      );
                                                    })
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed: () => deleteRecharge(_recharges[index]),
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                                "${_recharges[index].timestamp
                                                    .toDate()
                                                    .day}-"
                                                    "${_recharges[index]
                                                    .timestamp
                                                    .toDate()
                                                    .month}-"
                                                    "${_recharges[index]
                                                    .timestamp
                                                    .toDate()
                                                    .year}\n"
                                                    "${_recharges[index]
                                                    .timestamp
                                                    .toDate()
                                                    .hour}:"
                                                    "${_recharges[index]
                                                    .timestamp
                                                    .toDate()
                                                    .minute}"),
                                            Spacer(),
                                            Text(
                                                "${_recharges[index]
                                                    .kwRecharged} kW"),
                                            Spacer(),
                                            Text("${_recharges[index]
                                                .cashSpent} €"),
                                          ],
                                        ),
                                      );
                                    })))
                      ],
                    ));
            }
            }
        });
  }

  Widget newKwRechargedForm(Recharge r) {
    return TextFormField(
      initialValue: r.kwRecharged.toString(),
      decoration: const InputDecoration(labelText: 'kW recharged'),
      keyboardType: TextInputType.number,
      validator: (value) {
        try {
          var parsedValue = double.parse(value);
          if (parsedValue < 0 || parsedValue > 500) {
            return 'kW should be a value\nbetween 0 and 500';
          }
        }
        catch (e) {
          return 'kW should be a value\nbetween 0 and 500';
        }

        return null;
      },
      onSaved: (String val) {
        var parsed = double.parse(val);
        _newKwRecharged = double.parse(parsed.toStringAsFixed(2));
      },
    );
  }

  Widget newCashSpentForm(Recharge r) {
    return TextFormField(
      initialValue: r.cashSpent.toString(),
      decoration: const InputDecoration(labelText: 'Cash spent'),
      keyboardType: TextInputType.number,
      validator: (value) {
        try {
          var parsedValue = double.parse(value);
          if (parsedValue < 0 || parsedValue > 100) {
            return 'Cash spent should be a value\nbetween 0 and 100';
          }
        }
        catch (e) {
          return 'Cash spent should be a value\nbetween 0 and 100';
        }

        return null;
      },
      onSaved: (String val) {
        var parsed = double.parse(val);
        _newCashSpent = double.parse(parsed.toStringAsFixed(2));
      },
    );
  }

  void modifyRecharge(Recharge recharge) async {
    var user = await _auth.currentUser();
    await Firestore.instance.collection("recharges").document(user.uid).collection("0").document(recharge.id).updateData({
      'cash_spent': _newCashSpent,
      'kw_recharged': _newKwRecharged
    });

    setState(() {
      _recharges.where((element) => element.id == recharge.id).first.cashSpent = _newCashSpent;
      _recharges.where((element) => element.id == recharge.id).first.kwRecharged = _newKwRecharged;
      updateStatistics();
    });
  }

  void deleteRecharge(Recharge recharge) async {
    var user = await _auth.currentUser();
    await Firestore.instance.collection("recharges").document(user.uid).collection("0").document(recharge.id).delete();

    setState(() {
      _recharges.remove(recharge);
      updateStatistics();
    });
  }

  void updateStatistics() {
    List<Recharge> temp;

    switch (_selectedGranularity) {
      case "Week":
        temp = _recharges.where((element) => Jiffy(element.timestamp.toDate()).week == Jiffy().week).toList();
        break;

      case "Month":
        temp = _recharges.where((element) => Jiffy(element.timestamp.toDate()).month == Jiffy().month).toList();
        break;

      case "Year":
        temp = _recharges.where((element) => Jiffy(element.timestamp.toDate()).year == Jiffy().year).toList();
        break;
    }

    _totalSpent = temp.fold(0, (previousValue, element) => previousValue + element.cashSpent);
    _totalRecharged = temp.fold(0, (previousValue, element) => previousValue + element.kwRecharged);

    _totalSpent == 0 ? _meanPrice = 0 : _meanPrice = _totalSpent / _totalRecharged;

    _totalSpent = double.parse(_totalSpent.toStringAsFixed(2));
    _totalRecharged = double.parse(_totalRecharged.toStringAsFixed(2));
    _meanPrice = double.parse(_meanPrice.toStringAsFixed(2));
  }

  Future<bool> getData() async {
    var user = await _auth.currentUser();

    final QuerySnapshot result = await Firestore.instance
        .collection('recharges')
        .document(user.uid)
        .collection('0')
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;
    if (result.documents.length > 0) {
      documents.forEach((data) {
        // Can't use data["range"] and data["battery"] directly
        // it hangs up
        // flutter firebase bug?
        var id = data.documentID;
        Timestamp timestamp = data["timestamp"];
        var cashSpent = double.parse(data["cash_spent"].toString());
        var kwRecharged = double.parse(data["kw_recharged"].toString());
        var r = Recharge(id, timestamp, cashSpent, kwRecharged);

        _recharges.add(r);
      });

      updateStatistics();
    }

    return true;
  }
}
