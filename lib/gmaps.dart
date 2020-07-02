import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:AlGa/recharge_manager.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:AlGa/charging_stations.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class Gmaps extends StatefulWidget {
  @override
  _Gmaps createState() => _Gmaps();
}

class _Gmaps extends State<Gmaps> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /* This is triggered when the user comes back to AlGa. For example, the user
       launches a navigation toward a station, but then she changes her mind.
       With this, we prevent the "tracking location" notification to be displayed
       when not needed.
    */
    if (state == AppLifecycleState.resumed)
      RechargeManager.stopLocationService();
  }

  Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  BitmapDescriptor greenStationIcon;
  BitmapDescriptor redStationIcon;
  List<ChargingStations> stations = new List();
  Position currPos = Position(latitude: 45.4642, longitude: 9.19);

  double pinPillPosition = -100;

  ChargingStations currentlySelectedStation =
      new ChargingStations(new GeoPoint(0, 0), 0, 0, true);

  final LatLng _center = const LatLng(45.4642, 9.1900);

  PanelController _pc = new PanelController();

  NumberFormat numberFormat = new NumberFormat("0.00");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setState(() {
      if (_pc.isAttached) _pc.isPanelClosed;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      SlidingUpPanel(
          controller: _pc,
          minHeight: 20,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
          onPanelOpened: () {
            setState(() {
              pinPillPosition = -100;
            });
          },
          panelBuilder: (ScrollController sc) => Center(
                  child: DefaultTabController(
                length: 3,
                initialIndex: 0,
                child: Column(children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(15.0),
                        ),
                        color: Colors.blue),
                    height: 30,
                    alignment: Alignment(0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 70,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0))),
                        ),
                      ],
                    ),
                  ),
                  Container(
                      color: Colors.blue,
                      child: TabBar(
                        tabs: <Widget>[
                          Tab(
                              icon: Icon(Icons.euro_symbol),
                              child: Text("order by\nprice",
                                  textAlign: TextAlign.center)),
                          Tab(
                              icon: Icon(Icons.shutter_speed),
                              child: Text("order by\nspeed",
                                  textAlign: TextAlign.center)),
                          Tab(
                              icon: Icon(Icons.drive_eta),
                              child: Text("order by\ndistance",
                                  textAlign: TextAlign.center)),
                        ],
                      )),
                  Expanded(
                    child: Container(
                      height: 300.0,
                      child: TabBarView(
                        physics: new NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          ListView.builder(
                            // Order By Price
                            controller: sc,
                            itemCount: stations.length,
                            itemBuilder: (BuildContext context, int index) {
                              List<ChargingStations> temp = stations;
                              _getLocation();
                              for (ChargingStations x in temp) {
                                x.distance = calculateDistance(
                                    currPos.latitude,
                                    currPos.longitude,
                                    x.pos.latitude,
                                    x.pos.longitude);
                              }
                              temp.sort((a, b) => a.price.compareTo(b.price));
                              return listItem(temp, index);
                            },
                          ),
                          ListView.builder(
                            // Order By Speed
                            controller: sc,
                            itemCount: stations.length,
                            itemBuilder: (BuildContext context, int index) {
                              List<ChargingStations> temp = stations;
                              _getLocation();
                              for (ChargingStations x in temp) {
                                x.distance = calculateDistance(
                                    currPos.latitude,
                                    currPos.longitude,
                                    x.pos.latitude,
                                    x.pos.longitude);
                              }
                              temp.sort((a, b) => -a.speed.compareTo(
                                  b.speed)); // "-" for descending order
                              return listItem(temp, index);
                            },
                          ),
                          ListView.builder(
                            // Order By Distance
                            controller: sc,
                            itemCount: stations.length,
                            itemBuilder: (BuildContext context, int index) {
                              List<ChargingStations> temp = stations;
                              _getLocation();
                              for (ChargingStations x in temp) {
                                x.distance = calculateDistance(
                                    currPos.latitude,
                                    currPos.longitude,
                                    x.pos.latitude,
                                    x.pos.longitude);
                              }
                              temp.sort(
                                  (a, b) => a.distance.compareTo(b.distance));
                              return listItem(temp, index);
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                ]),
              )),
          body: GoogleMap(
            onMapCreated: _onMapCreated,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            compassEnabled: true,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 13.0,
            ),
            markers: _markers,
            onTap: (LatLng location) {
              setState(() {
                pinPillPosition = -100;
              });
            },
          )),
      AnimatedPositioned(
          bottom: pinPillPosition,
          right: 0,
          left: 0,
          duration: Duration(milliseconds: 200),
          child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                  margin: EdgeInsets.all(20),
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            blurRadius: 20,
                            offset: Offset.zero,
                            color: Colors.grey.withOpacity(0.5))
                      ]),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(left: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                    "Price: ${currentlySelectedStation.price.toString()}€/kW",
                                    style: TextStyle(color: Colors.green)),
                                Text(
                                    "Speed: ${currentlySelectedStation.speed.toString()}kW/h",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                    "Available: ${currentlySelectedStation.available == true ? "YES" : "NO"}",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
                              ],
                            ),
                          ),
                        ),
                        FlatButton(
                          onPressed: () {
                            _launchMapsUrl(
                                currentlySelectedStation.pos.latitude,
                                currentlySelectedStation.pos.longitude);
                            RechargeManager.startRechargeMonitor(
                                currentlySelectedStation);
                          },
                          child: Text(
                            "GO",
                            style: TextStyle(color: Colors.blue),
                          ),
                        )
                      ])))),
    ]);
  }

  Widget listItem(temp, index) {
    return ListTile(
      title: Text(
          "Distance: ${numberFormat.format(temp[index].distance).toString()} Km",
          style: TextStyle(color: temp[index].available ? Colors.green : Colors.red)),
      subtitle: Text(
          "Speed: ${temp[index].speed.toString()}kW/h Price: ${temp[index].price.toString()}€/kW",
          style: TextStyle(
              fontSize: 12, color: Colors.grey)),
      trailing: SizedBox(
          width: MediaQuery.of(context).size.width * 0.38,
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.gps_fixed),
                iconSize: 20,
                onPressed: () => {
                  setState(() {
                    _pc.close();
                    currentlySelectedStation = temp[index];
                    var pos = new Position(latitude: currentlySelectedStation.pos.latitude, longitude: currentlySelectedStation.pos.longitude);
                    _moveToPosition(pos);
                    pinPillPosition = 20;
                  })
                },
              ),
              FlatButton(
                onPressed: () {
                  _launchMapsUrl(temp[index].pos.latitude,
                      temp[index].pos.longitude);
                  RechargeManager.startRechargeMonitor(
                      temp[index]);
                },
                child: Text(
                  "GO",
                  style: TextStyle(color: Colors.blue),
                ),
              )
            ],
          )),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    checkGeoPermission();
    await _getLocation();
    setCustomMapPin();
    await _moveToPosition(currPos);
  }

  void setCustomMapPin() async {
    final Uint8List greenStation =
        await getBytesFromAsset('assets/station_green.png', 140);
    greenStationIcon = BitmapDescriptor.fromBytes(greenStation);

    final Uint8List redStation =
    await getBytesFromAsset('assets/station_red.png', 140);
    redStationIcon = BitmapDescriptor.fromBytes(redStation);

    await getData();

    setState(() {
      var i = 0;
      for (var elem in stations) {
        _markers.add(Marker(
          markerId: MarkerId("charger: $i"),
          position: LatLng(elem.pos.latitude, elem.pos.longitude),
          onTap: () {
            setState(() {
              currentlySelectedStation = elem;
              pinPillPosition = 20;
            });
          },
          icon: elem.available ? greenStationIcon : redStationIcon,
        ));
        i++;
      }
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  Future<void> getData() async {
    final QuerySnapshot result =
        await Firestore.instance.collection('charging_stations').getDocuments();
    final List<DocumentSnapshot> documents = result.documents;

    documents.forEach((data) => stations.add(ChargingStations(
        data["pos"], data["speed"], data["price"], data["available"])));
  }

  void _launchMapsUrl(double latitude, double longitude) async {
    await _getLocation();
    final url =
        'https://www.google.com/maps/dir/${currPos.latitude},${currPos.longitude}/$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void checkGeoPermission() async {
    bool serviceStatus = await Geolocator().isLocationServiceEnabled();
    if (!serviceStatus)
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Location not enabled."),
      ));
  }

  Future<void> _getLocation() async {
    bool serviceStatus = await Geolocator().isLocationServiceEnabled();
    if (serviceStatus)
      currPos = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  Future<void> _moveToPosition(Position currPos) async {
    final GoogleMapController mapController = await _mapController.future;
    if (mapController == null) return;
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(currPos.latitude, currPos.longitude),
      zoom: 15.0,
    )));
  }
}

double calculateDistance(
    double initialLat, double initialLong, double finalLat, double finalLong) {
  int R = 6371;
  double dLat = toRadians(finalLat - initialLat);
  double dLon = toRadians(finalLong - initialLong);
  initialLat = toRadians(initialLat);
  finalLat = toRadians(finalLat);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(initialLat) * cos(finalLat);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double toRadians(double deg) {
  return deg * pi / 180.0;
}
