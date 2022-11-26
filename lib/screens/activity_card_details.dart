import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';

class ActivityCardDetails extends StatefulWidget {
  @override
  _ActivityCardDetailsState createState() => _ActivityCardDetailsState();
}

class _ActivityCardDetailsState extends State<ActivityCardDetails> {
  bool isLoading = false;

  Future<void> refresh(FeedItemModel feedItem) async {
    setState(() {
      isLoading = true;
    });
    final feedItemData = await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.getId).get();
    final likesUsersDocs = await feedItemData.reference.collection('likes_users').get();
    final likesUsersDocsList = likesUsersDocs.docs.toList();
    final likesUsersDocsListIds = likesUsersDocsList.map((e) => e.id);
    feedItem.setLikes = likesUsersDocsList.length - 1;
    feedItem.setCommentsNumber = feedItemData.data()['number_comments'];
    feedItem.setUserLikes = likesUsersDocsList;
    feedItem.setCurrentUserLike = likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid);
    setState(() {
      isLoading = false;
    });
  }

  Set<Marker> createMarkers(FeedItemModel feedItem) {
    final Set<Marker> markers = {};
    List<LatLng> listCoordinates = feedItem.getCoordinates.map((e) => LatLng(e['lat'], e['lng'])).toList();

    markers.add(Marker(
      markerId: MarkerId('start'),
      position: listCoordinates.first,
    ));

    markers.add(Marker(
      markerId: MarkerId('end'),
      position: listCoordinates.last,
    ));

    return markers;
  }

  Set<Polyline> createPolyLine(FeedItemModel feedItem) {
    List<LatLng> listCoordinates = feedItem.getCoordinates.map((e) => LatLng(e['lat'], e['lng'])).toList();

    return {
      Polyline(
        width: 5,
        polylineId: PolylineId('poly'),
        color: Color.fromARGB(255, 40, 122, 198),
        points: listCoordinates,
      )
    };
  }

  @override
  Widget build(BuildContext context) {
    FeedItemModel feedItem = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes de atividade"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () {
                return refresh(feedItem);
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Card(
                  child: Column(
                    children: <Widget>[
                      Column(
                        children: [
                          ListTile(
                            leading: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile', arguments: feedItem.getUserId).then((value) => refresh(feedItem));
                              },
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(feedItem.avatarUrl),
                                radius: 28,
                              ),
                            ),
                            title: Text(
                              feedItem.getTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 19,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat.yMMMMd().format(feedItem.getDateTime) + " às " + DateFormat.jm().format(feedItem.getDateTime),
                            ),
                            trailing: FirebaseAuth.instance.currentUser.uid == feedItem.getUserId
                                ? PopupMenuButton(
                                    child: IconButton(
                                      iconSize: 32,
                                      icon: Icon(Icons.more_vert),
                                    ),
                                    itemBuilder: (context) {
                                      return [
                                        // PopupMenuItem(
                                        //   child: Text('Editar'),
                                        // ),
                                        PopupMenuItem(
                                          child: InkWell(
                                            child: Text('Excluir'),
                                            onTap: () {
                                              showMyDialog(feedItem, context, 'activity');
                                            },
                                          ),
                                        )
                                      ];
                                    },
                                  )
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 10),
                              child: Text(
                                feedItem.getDescription,
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,

                              children: [
                                Container(

                                  child: Column(
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            "Distância",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            (feedItem.getDistance / 1000).toStringAsFixed(2) + 'km',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Column(
                                        children: [
                                          Text(
                                            "Velocidade Média",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            ((feedItem.getDistance / feedItem.getDuration) * 3.6).toStringAsFixed(1) + 'km/h',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          SizedBox(height: 16)
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  // width: 190,
                                  child: Column(
                                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            "Tempo",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            printDuration(Duration(seconds: feedItem.getDuration), false),
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Column(
                                        children: [
                                          Text(
                                            "CO2 não emitido",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            (feedItem.getDistance / 1000 * 0.25).toStringAsFixed(2) + 'kg',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          SizedBox(height: 16)
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.50,
                            child: GoogleMap(
                              gestureRecognizers: {
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                              initialCameraPosition: CameraPosition(
                                target: LatLng(feedItem.getCoordinates[0]['lat'], feedItem.getCoordinates[0]['lng']),
                                zoom: 13.0,
                              ),
                              polylines: createPolyLine(feedItem),
                              markers: createMarkers(feedItem),
                            ),
                          ),
                          if (feedItem.getImageUrl != null && feedItem.getImageUrl != "") Container(
                            margin: EdgeInsets.only(top: 20, left: 10, right: 10),
                            height: MediaQuery.of(context).size.height * 0.40,
                            child: Image.network(feedItem.getImageUrl),
                          ),
                        ],
                      ),
                      ButtonBar(
                        alignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: [
                              FlatButton(
                                child: feedItem.currentUserLike ? Icon(Icons.thumb_up) : Icon(Icons.thumb_up_outlined),
                                onPressed: () async {
                                  setState(() {
                                    if (feedItem.currentUserLike) {
                                      feedItem.likes -= 1;
                                    } else {
                                      feedItem.likes += 1;
                                    }
                                    feedItem.currentUserLike = !feedItem.currentUserLike;
                                  });

                                  await toggleLike(feedItem, !feedItem.currentUserLike);
                                  // setState(() {});
                                },
                              ),
                              FlatButton(
                                child: Icon(Icons.comment_outlined),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/add_comment', arguments: feedItem).then((value) => setState(() {
                                        refresh(feedItem);
                                      }));
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/likes', arguments: feedItem.getId);
                                },
                                child: feedItem.likes == 1
                                    ? Text(feedItem.likes.toString() + " curtida")
                                    : Text(feedItem.likes.toString() + " curtidas"),
                              ),
                              SizedBox(width: 20),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/show_comments', arguments: feedItem).then((value) => setState(() {
                                        refresh(feedItem);
                                      }));
                                },
                                child: Text("${feedItem.getCommentsNumber} comentários"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
