import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:AlGa/charging_stations.dart';

class Gmaps extends StatefulWidget {
  @override
  _Gmaps createState() => _Gmaps();
}


class _Gmaps extends State<Gmaps> {
  Completer<GoogleMapController> _mapController = Completer();
  Map<String, Marker> _markers = {};
  BitmapDescriptor carIcon;
  BitmapDescriptor stationIcon;
  List<ChargingStations> stations = new List();
  Position currPos;

  double pinPillPosition = -100;

  ChargingStations currentlySelectedStation = new ChargingStations(new GeoPoint(0, 0), 0, 0);

  final LatLng _center = const LatLng(45.4642, 9.1900);

  void _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    await _getLocation();
    await _moveToPosition(currPos);
  }

  @override
  void initState() {
    super.initState();
    setCustomMapPin();
  }

  void setCustomMapPin() async {
    //final Uint8List car = await getBytesFromAsset('assets/car_icon.png', 150);
    final Uint8List station = await getBytesFromAsset('assets/station_green.png', 140);
    //carIcon = BitmapDescriptor.fromBytes(car);
    stationIcon = BitmapDescriptor.fromBytes(station);

    await getData();

    setState(() {
      int i = 0;
      for (var elem in stations) {
        _markers["$i"] = Marker(
          markerId: MarkerId("charger: $i"),
          position: LatLng(elem.pos.latitude, elem.pos.longitude),
          onTap: () {
            setState(() {
              currentlySelectedStation = elem;
              pinPillPosition = 0;
            });
          },
          icon: stationIcon,
        );
        i++;
      }
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }

  Future<void> getData() async {
    final QuerySnapshot result = await Firestore.instance.collection('charging_stations').getDocuments();
    final List<DocumentSnapshot> documents = result.documents;

    documents.forEach((data) => stations.add(ChargingStations(data["pos"], data["speed"], data["price"])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget> [
          GoogleMap(
            onMapCreated: _onMapCreated,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            compassEnabled: true,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 13.0,
            ),
            markers: _markers.values.toSet(),
            onTap: (LatLng location) {
              setState(() {
                pinPillPosition = -100;
              });
            },
          ),
          AnimatedPositioned(
            bottom: pinPillPosition, right: 0, left: 0,
            duration: Duration(milliseconds: 200),
            child: Align(
              alignment: Alignment.bottomLeft,
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
                      color: Colors.grey.withOpacity(0.5)
                    )
                  ]
                ),
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
                              style: TextStyle(
                                color: Colors.green
                              )
                            ),
                            Text(
                              "Speed: ${currentlySelectedStation.speed.toString()}kW/h",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey
                              )
                            ),
                            Text("Available: YES",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey
                              )
                            )
                          ],
                        ),
                      ),
                    ),
                    FlatButton(
                      onPressed: () {
                        _launchMapsUrl(currentlySelectedStation.pos.latitude, currentlySelectedStation.pos.longitude);
                      },
                      child: Text(
                        "GO",
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                  ]
                )
              )
            )
          )
        ],
    ),
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: _getLocation,
        tooltip: 'Get Location',
        child: Icon(Icons.gps_fixed),
      )
      */
    );
  }

  void _launchMapsUrl(double latitude, double longitude)   async {
    await _getLocation();
    final url = 'https://www.google.com/maps/dir/${currPos.latitude},${currPos.longitude}/$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _getLocation() async {
    currPos = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  Future<void> _moveToPosition(Position currPos) async {
    final GoogleMapController mapController = await _mapController.future;
    if(mapController == null) return;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currPos.latitude, currPos.longitude),
          zoom: 15.0,
        )
      )
    );
  }
}