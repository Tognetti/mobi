import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';
import 'package:mobi/widgets/help_request_map.dart';

class HelpMapScreen extends StatefulWidget {
  @override
  _HelpMapScreenState createState() => _HelpMapScreenState();
}

class _HelpMapScreenState extends State<HelpMapScreen> {
  bool isLoading = false;

  Future<QuerySnapshot> checkActiveHelpRequest() async {
    QuerySnapshot helpRequestData = await FirebaseFirestore.instance
        .collection('help_request')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    return helpRequestData;
  }

  Future<FeedItemModel> getFeedItemData(List<QueryDocumentSnapshot> helpRequestDocList) async {
    if (helpRequestDocList.length > 0) {
      QueryDocumentSnapshot helpRequestDoc = helpRequestDocList[0];
      QuerySnapshot feedItemDocList =
          await FirebaseFirestore.instance.collection('feed_item').where('help_request_id', isEqualTo: helpRequestDoc.id).get();
      if (feedItemDocList.docs.length > 0) {
        QueryDocumentSnapshot feedItemDoc = feedItemDocList.docs[0];
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(helpRequestDoc.data()['user_id']).get();
        return FeedItemModel(
          id: feedItemDoc.id,
          profileName: helpRequestDoc.data()['user_name'],
          activityTitle: helpRequestDoc.data()['title'],
          activityDescription: helpRequestDoc.data()['description'],
          imageUrl: helpRequestDoc.data()['image_url'],
          avatarUrl: userData.data()['image_url'],
          type: feedItemDoc.data()['type'],
          dateTime: DateTime.parse(feedItemDoc.data()['date_time']),
          userId: helpRequestDoc.data()['user_id'],
          parentId: helpRequestDoc.id,
          latitude: helpRequestDoc.data()['latitude'],
          longitude: helpRequestDoc.data()['longitude'],
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Criar um pedido de ajuda"),
      ),
      body: FutureBuilder(
        future: checkActiveHelpRequest(),
        builder: (context, helpRequestSnapshot) {
          if (helpRequestSnapshot.connectionState == ConnectionState.done) {
            if (helpRequestSnapshot.data.docs.length == 0) {
              return FutureBuilder(
                future: setInitialLocation(),
                builder: (context, locationSnapshot) {
                  if (locationSnapshot.hasData) {
                    return HelpRequestMap(locationSnapshot.data.latitude, locationSnapshot.data.longitude);
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              );
            } else {
              return isLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : InkWell(
                      onTap: () async {
                        setState(() {
                          isLoading = true;
                        });
                        var feedItem = await getFeedItemData(helpRequestSnapshot.data.docs);
                        BitmapDescriptor helpIcon = await BitmapDescriptor.fromAssetImage(
                            ImageConfiguration(devicePixelRatio: 1), 'lib/assets/images/help_icon.png');
                        Set<Marker> _markers = {};
                        _markers.add(Marker(
                          markerId: MarkerId('1'),
                          position: LatLng(
                              helpRequestSnapshot.data.docs[0].data()['latitude'], helpRequestSnapshot.data.docs[0].data()['longitude']),
                          icon: helpIcon,
                        ));
                        setState(() {
                          isLoading = false;
                        });
                        Navigator.pushNamed(context, '/help_card_details', arguments: [feedItem, _markers]);
                      },
                      child: Card(
                        elevation: 3,
                        margin: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                          child: Row(
                            children: [
                              Image.asset(
                                'lib/assets/images/help_icon.png',
                                scale: 2,
                              ),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Você já possui um pedido de ajuda ativo, aperte aqui para ver mais detalhes',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
