import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertCardDetails extends StatefulWidget {
  @override
  _AlertCardDetailsState createState() => _AlertCardDetailsState();
}

class _AlertCardDetailsState extends State<AlertCardDetails> {
  bool isLoading = false;

  Future<void> refresh(FeedItemModel feedItem) async {
    setState(() {
      isLoading = true;
    });
    final feedItemData = await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.getId).get();
    final likesUsersDocs = await feedItemData.reference.collection('likes_users').get();
    final likesUsersDocsList = likesUsersDocs.docs.toList();
    final likesUsersDocsListIds = likesUsersDocsList.map((e) => e.id);
    feedItem.setLikes = likesUsersDocsListIds.length - 1;
    feedItem.setCommentsNumber = feedItemData.data()['number_comments'];
    feedItem.setUserLikes = likesUsersDocsList;
    feedItem.setCurrentUserLike = likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> args = ModalRoute.of(context).settings.arguments;
    FeedItemModel feedItem = args[0];
    Set<Marker> markers = args[1];
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes de alerta"),
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
                                              showMyDialog(feedItem, context, 'alert');
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
                          Container(
                            margin: EdgeInsets.only(bottom: 20, left: 10, right: 10),
                            height: 250,
                            child: Image.network(feedItem.getImageUrl),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.50,
                            child: GoogleMap(
                              markers: markers,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(feedItem.getLatitude, feedItem.getLongitude),
                                zoom: 15.0,
                              ),
                            ),
                          ),
                          TextButton(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "Veja este alerta no mapa ",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Container(
                                  width: 25,
                                  child: Image.asset(
                                    'lib/assets/images/map_icon.png',
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/show_map_screen', arguments: [feedItem.getLatitude, feedItem.getLongitude]);
                            },
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
