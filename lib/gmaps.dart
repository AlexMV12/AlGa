import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  final LatLng _center = const LatLng(45.4642, 9.1900);

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  @override
  void initState() {
    super.initState();
    setCustomMapPin();
    /*
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), 'assets/car_icon.png')
        .then((onValue) {
      myIcon = onValue;
    });
     */
  }

  void setCustomMapPin() async {
    myIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(3, 3)),
        'assets/car_icon.png');
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
    });
  }

  Future<void> _moveToPosition(Position pos) async {
    final GoogleMapController mapController = await _mapController.future;
    if(mapController == null) return;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 15.0,
        )
      )
    );
  }
}