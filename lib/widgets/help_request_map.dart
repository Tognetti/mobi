import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HelpRequestMap extends StatefulWidget {
  final initialLatitude;
  final initialLongitude;

  HelpRequestMap(this.initialLatitude, this.initialLongitude);

  @override
  _HelpRequestMapState createState() => _HelpRequestMapState();
}

class _HelpRequestMapState extends State<HelpRequestMap> {
  BitmapDescriptor pinLocationIcon;
  Set<Marker> _markers = {};
  var selectedLatitude;
  var selectedLongitude;

  @override
  void initState() {
    super.initState();
    setCustomMapPin();
  }

  void setCustomMapPin() async {
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 0.5), 'lib/assets/images/help_icon.png');
  }

  void _onAddMarkerButtonPressed(LatLng latlang) {
    _markers = {};
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
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.70,
          child: GoogleMap(
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initialLatitude, widget.initialLongitude),
              zoom: 15.0,
            ),
            onTap: (latlang) {
              _onAddMarkerButtonPressed(latlang);
              selectedLatitude = latlang.latitude;
              selectedLongitude = latlang.longitude;
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
                      Navigator.pushNamed(context, '/help_create', arguments: [selectedLatitude, selectedLongitude]);
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
                      "Selecione um lugar no mapa para o pedido",
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
    );
  }
}
