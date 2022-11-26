import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';

class ShowMapScreen extends StatefulWidget {
  @override
  _ShowMapScreenState createState() => _ShowMapScreenState();
}

class _ShowMapScreenState extends State<ShowMapScreen> {
  BitmapDescriptor helpIcon, alertIcon;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    setCustomMapPin();
    loadMarkers();
    super.initState();
  }

  Future<FeedItemModel> getAlertFeedItem(alert, feedItemId) async {
    var feedItemDoc = await FirebaseFirestore.instance.collection('feed_item').doc(feedItemId).get();
    var likesUsersDocs = await feedItemDoc.reference.collection('likes_users').get();
    var likesUsersDocsList = likesUsersDocs.docs.toList();
    var likesUsersDocsListIds = likesUsersDocsList.map((e) => e.id);
    final userData = await FirebaseFirestore.instance.collection('users').doc(alert.data()['user_id']).get();
    return FeedItemModel(
      id: feedItemDoc.id,
      profileName: alert.data()['user_name'],
      activityTitle: alert.data()['title'],
      activityDescription: alert.data()['description'],
      imageUrl: alert.data()['image_url'],
      avatarUrl: userData.data()['image_url'],
      type: feedItemDoc.data()['type'],
      dateTime: DateTime.parse(feedItemDoc.data()['date_time']),
      likes: likesUsersDocsList.length - 1,
      likesUsers: likesUsersDocsList,
      currentUserLike: likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid),
      userId: alert.data()['user_id'],
      parentId: alert.id,
      comments: feedItemDoc.data()['number_comments'],
      latitude: alert.data()['latitude'],
      longitude: alert.data()['longitude'],
    );
  }

  Future<FeedItemModel> getHelpFeedItem(help, feedItemId) async {
    var feedItemDoc = await FirebaseFirestore.instance.collection('feed_item').doc(feedItemId).get();
    final userData = await FirebaseFirestore.instance.collection('users').doc(help.data()['user_id']).get();
    return FeedItemModel(
      id: feedItemDoc.id,
      profileName: help.data()['user_name'],
      activityTitle: help.data()['title'],
      activityDescription: help.data()['description'],
      imageUrl: help.data()['image_url'],
      avatarUrl: userData.data()['image_url'],
      type: feedItemDoc.data()['type'],
      dateTime: DateTime.parse(feedItemDoc.data()['date_time']),
      userId: help.data()['user_id'],
      parentId: help.id,
      latitude: help.data()['latitude'],
      longitude: help.data()['longitude'],
    );
  }

  void setCustomMapPin() async {
    helpIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 1), 'lib/assets/images/help_icon.png');
    alertIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 1), 'lib/assets/images/alert_icon.png');
  }

  loadMarkers() async {
    var alertsSnapshot = await FirebaseFirestore.instance.collection('alerts').get();
    var helpSnapshot = await FirebaseFirestore.instance.collection('help_request').where('active', isEqualTo: true).get();

    setState(() {
      alertsSnapshot.docs.forEach((element) {
        _markers.add(
          Marker(
            icon: alertIcon,
            markerId: MarkerId(element.id),
            position: LatLng(element.data()['latitude'], element.data()['longitude']),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                        child: Column(
                          children: <Widget>[
                            Text(
                              element.data()['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(element.data()['description']),
                            SizedBox(height: 20),
                            Text("Criado por " + element.data()['user_name']),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                var feedItem = await getAlertFeedItem(element, element.data()['feed_item_id']);
                                final Set<Marker> alertMarkers = {};
                                alertMarkers.add(Marker(
                                  markerId: MarkerId('1'),
                                  position: LatLng(feedItem.getLatitude, feedItem.getLongitude),
                                  icon: alertIcon,
                                ));
                                Navigator.pushNamed(
                                  context,
                                  '/alert_card_details',
                                  arguments: [feedItem, alertMarkers],
                                );
                              },
                              child: Text('Ver mais detalhes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      });
      helpSnapshot.docs.forEach((element) {
        _markers.add(
          Marker(
            icon: helpIcon,
            markerId: MarkerId(element.id),
            position: LatLng(element.data()['latitude'], element.data()['longitude']),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                        child: Column(
                          children: <Widget>[
                            Text(
                              element.data()['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(element.data()['description']),
                            SizedBox(height: 20),
                            Text("Criado por " + element.data()['user_name']),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                var feedItem = await getHelpFeedItem(element, element.data()['feed_item_id']);
                                final Set<Marker> markers = {};
                                markers.add(Marker(
                                  markerId: MarkerId('1'),
                                  position: LatLng(feedItem.getLatitude, feedItem.getLongitude),
                                  icon: helpIcon,
                                ));
                                Navigator.pushNamed(
                                  context,
                                  '/help_card_details',
                                  arguments: [feedItem, markers],
                                );
                              },
                              child: Text('Ver mais detalhes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> args = ModalRoute.of(context).settings.arguments;
    double latitude;
    double longitude;
    if (args != null) {
      latitude = args[0];
      longitude = args[1];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Alertas e pedidos"),
      ),
      body: FutureBuilder(
        future: setInitialLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (latitude != null && longitude != null) {
              return GoogleMap(
                myLocationEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 18.0,
                ),
                markers: _markers,
              );
            } else {
              return GoogleMap(
                myLocationEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: LatLng(snapshot.data.latitude, snapshot.data.longitude),
                  zoom: 14.0,
                ),
                markers: _markers,
              );
            }
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
