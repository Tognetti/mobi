import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/backoffice/utils.dart';

class AlertScreen extends StatefulWidget {
  @override
  _AlertScreenState createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  BitmapDescriptor pinLocationIcon;
  final Set<Marker> _markers = {};
  var latitude;
  var longitude;

  @override
  void initState() {
    super.initState();
    setCustomMapPin();
  }

  void setCustomMapPin() async {
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 1), 'lib/assets/images/alert_icon.png');
  }

  void _onAddMarkerButtonPressed(LatLng latlang) {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId("1"),
        position: latlang,
        icon: pinLocationIcon,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Criar um alerta"),
      ),
      body: FutureBuilder(
        future: setInitialLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.70,
                    child: GoogleMap(
                      myLocationEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(snapshot.data.latitude, snapshot.data.longitude),
                        zoom: 14.0,
                      ),
                      onTap: (latlang) {
                        _onAddMarkerButtonPressed(latlang);
                        latitude = latlang.latitude;
                        longitude = latlang.longitude;
                      },
                      markers: _markers,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 15),
                    child: SizedBox(
                      width: 250,
                      height: 50,
                      child: RaisedButton(
                        color: Colors.green,
                        onPressed: _markers.length > 0
                            ? () {
                                Navigator.pushNamed(context, '/alert_detail', arguments: [latitude, longitude]);
                              }
                            : null,
                        child: _markers.length > 0
                            ? Text(
                                "Escolher localização",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              )
                            : Text(
                                "Selecione um lugar no mapa para o alerta",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
