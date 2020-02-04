import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Gmaps extends StatefulWidget {
  @override
  _Gmaps createState() => _Gmaps();
}


class _Gmaps extends State<Gmaps> {
  Completer<GoogleMapController> _mapController = Completer();
  final Map<String, Marker> _markers = {};
  BitmapDescriptor myIcon;
  List<GeoPoint> _pos = new List();

  final LatLng _center = const LatLng(45.4642, 9.1900);

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  @override
  void initState() {
    super.initState();
    setCustomMapPin();
  }

  void setCustomMapPin() async {
    final Uint8List markerIcon = await getBytesFromAsset('assets/car_icon.png', 150);
    myIcon = BitmapDescriptor.fromBytes(markerIcon);
    await getData();
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

    documents.forEach((data) => _pos.add(data["pos"]));
    /*
    Firestore.instance
        .collection("charging_stations")
        .document("eY12sQWkyATy9hnXiwtU")
        .get()
        .then((DocumentSnapshot ds) {
      _pos = ds["pos"];
    });
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 13.0,
        ),
        markers: _markers.values.toSet(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getLocation,
        tooltip: 'Get Location',
        child: Icon(Icons.flag),
      ),
    );
  }

  void _getLocation() async {
    var currentLocation = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    await _moveToPosition(currentLocation);

    setState(() {
      _markers.clear();
      final marker = Marker(
        markerId: MarkerId("curr_loc"),
        position: LatLng(currentLocation.latitude, currentLocation.longitude),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: myIcon
      );
      _markers["Current Location"] = marker;
      int i = 0;
      for (var elem in _pos) {
        _markers["${i}"] = Marker(
          markerId: MarkerId("charger: ${i}"),
          position: LatLng(elem.latitude, elem.longitude),
          infoWindow: InfoWindow(title: "Charger: ${i}"),
        );
        i++;
      }
    });
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