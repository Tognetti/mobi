import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class Arguments {
  final Duration time;
  final double distance;
  final List<LatLng> coordinates;

  Arguments(this.time, this.distance, this.coordinates);
}

class ActivityInfo extends StatefulWidget {
  const ActivityInfo(this.updateLine, this.coordinates);

  final List<LatLng> coordinates;
  final void Function(double lat, double lng) updateLine;

  @override
  _ActivityInfoState createState() => _ActivityInfoState();
}

class _ActivityInfoState extends State<ActivityInfo> {
  bool _isRecording = false;
  bool _activityStarted = false;
  bool _activityStoped = false;
  StreamSubscription<LocationData> _locationSubscription;
  Stopwatch _stopwatch = new Stopwatch();
  Timer timer;
  double _meters = 0;
  static const oneSec = const Duration(seconds: 1);
  var location = new Location();
  LocationData previousLocation;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    location.enableBackgroundMode(enable: true);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
  }

  void addDistance(currentLat, currentLng, previousLat, previousLng) async {
    _meters += GeolocatorPlatform.instance.distanceBetween(currentLat, currentLng, previousLat, previousLng);
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Distância",
                      style: TextStyle(fontSize: 24),
                    ),
                    Text(
                      (_meters / 1000).toStringAsFixed(2) + 'km',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FloatingActionButton(
                  child: _isRecording ? Icon(Icons.pause) : Icon(Icons.play_arrow),
                  onPressed: () {
                    _activityStarted = true;
                    setState(() {
                      if (_isRecording) {
                        _locationSubscription.cancel();
                        _stopwatch.stop();
                        timer.cancel();
                        _activityStoped = true;
                      } else {
                        _activityStoped = false;
                        _stopwatch.start();
                        timer = new Timer.periodic(oneSec, (Timer t) {
                          if (!_disposed) {
                            setState(() {});
                          }
                        });
                        _locationSubscription = location.onLocationChanged.listen((LocationData cLoc) {
                          if (previousLocation != null) {
                            addDistance(cLoc.latitude, cLoc.longitude, previousLocation.latitude, previousLocation.longitude);
                          }
                          previousLocation = cLoc;
                          widget.updateLine(cLoc.latitude, cLoc.longitude);
                        });
                      }
                      _isRecording = !_isRecording;
                    });
                  },
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Tempo",
                      style: TextStyle(fontSize: 22),
                    ),
                    Text(
                      _printDuration(_stopwatch.elapsed),
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 300,
          height: 50,
          child: RaisedButton(
            child: Text(
              _activityStarted ? (_activityStoped ? "Concluir atividade" : "Atividade em andamento") : "Comece a atividade!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            onPressed: _activityStarted && _activityStoped
                ? () {
                    Navigator.pushNamed(context, '/activity_finish', arguments: Arguments(_stopwatch.elapsed, _meters, widget.coordinates));
                  }
                : null,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
