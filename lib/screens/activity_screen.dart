import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobi/widgets/activity_info.dart';

class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  GoogleMapController _controller;

  Future<Position> setInitialLocation() async {
    Position initialPosition = await GeolocatorPlatform.instance.getCurrentPosition();
    return initialPosition;
  }

  void updateLine(lat, lng) async {
    polylineCoordinates.add(LatLng(lat, lng));

    _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15.0,
        ),
      ),
    );
    setState(() {
      _polylines.add(Polyline(
        width: 5,
        polylineId: PolylineId('poly'),
        color: Color.fromARGB(255, 40, 122, 198),
        points: polylineCoordinates,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar atividade"),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder(
            future: setInitialLocation(),
            builder: (context, initialLocationSnapshot) {
              if (initialLocationSnapshot.hasData) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.60,
                  child: GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(initialLocationSnapshot.data.latitude, initialLocationSnapshot.data.longitude),
                      zoom: 15.0,
                    ),
                    polylines: _polylines,
                    onMapCreated: (GoogleMapController controller) {
                      _controller = controller;
                    },
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Expanded(child: ActivityInfo(updateLine, polylineCoordinates)),
        ],
      ),
    );
  }
}
