import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/models/feed_item_model.dart';

import 'feed_card.dart';

// ignore: must_be_immutable
class ProfileFeed extends StatefulWidget {
  List<FeedItemModel> userFeed;
  Function refresh;
  bool showEndButton;
  bool lastFeedItem;
  bool endScreenLoading;
  String userId;
  FeedItemModel helpFeedItem;
  List<QueryDocumentSnapshot> feedItemCollectionDocs;
  List<QueryDocumentSnapshot> newFeedItemsDocs;
  var username;

  ProfileFeed(this.username, this.userFeed, this.refresh, this.showEndButton, this.lastFeedItem, this.endScreenLoading, this.userId,
      this.feedItemCollectionDocs);

  @override
  _ProfileFeedState createState() => _ProfileFeedState();
}

class _ProfileFeedState extends State<ProfileFeed> {
  Future<void> _fetchData;

  Future<void> fetchData(userId, bool firstFetch) async {
    QuerySnapshot feedItemCollection;

    if (firstFetch) {
      widget.userFeed = [];
      feedItemCollection = await FirebaseFirestore.instance
          .collection('feed_item')
          .where('user_id', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .orderBy('date_time', descending: true)
          .limit(5)
          .get();
      widget.newFeedItemsDocs = feedItemCollection.docs;
      widget.feedItemCollectionDocs = feedItemCollection.docs;
    } else {
      if (widget.feedItemCollectionDocs.isNotEmpty) {
        feedItemCollection = await FirebaseFirestore.instance
            .collection('feed_item')
            .where('user_id', isEqualTo: userId)
            .where('active', isEqualTo: true)
            .orderBy('date_time', descending: true)
            .startAfterDocument(widget.feedItemCollectionDocs.last)
            .limit(5)
            .get();
        widget.newFeedItemsDocs = feedItemCollection.docs;
        widget.feedItemCollectionDocs.addAll(widget.newFeedItemsDocs);
      }
    }

    if (feedItemCollection != null && feedItemCollection.size == 0) {
      widget.lastFeedItem = true;
      widget.showEndButton = false;
      return FirebaseFirestore.instance.collection('users').doc(userId).get();
    }

    print(widget.feedItemCollectionDocs);
    for (var element in widget.newFeedItemsDocs) {
      final likesUsersDocs = await element.reference.collection('likes_users').get();
      final likesUsersDocsList = likesUsersDocs.docs.toList();
      final likesUsersDocsListIds = likesUsersDocsList.map((e) => e.id);

      if (element.data()['type'] == "alert") {
        final alertData = await FirebaseFirestore.instance.collection('alerts').doc(element.data()['alert_id']).get();
        final userData = await FirebaseFirestore.instance.collection('users').doc(alertData.data()['user_id']).get();

        widget.userFeed.add(FeedItemModel(
          id: element.id,
          profileName: alertData.data()['user_name'],
          activityTitle: alertData.data()['title'],
          activityDescription: alertData.data()['description'],
          imageUrl: alertData.data()['image_url'],
          avatarUrl: userData.data()['image_url'],
          type: element.data()['type'],
          dateTime: DateTime.parse(element.data()['date_time']),
          likes: likesUsersDocsList.length - 1,
          likesUsers: likesUsersDocsList,
          currentUserLike: likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid),
          userId: alertData.data()['user_id'],
          parentId: alertData.id,
          comments: element.data()['number_comments'],
          latitude: alertData.data()['latitude'],
          longitude: alertData.data()['longitude'],
        ));
      } else if (element.data()['type'] == "activity") {
        final activityData = await FirebaseFirestore.instance.collection('activities').doc(element.data()['activity_id']).get();
        final userData = await FirebaseFirestore.instance.collection('users').doc(activityData.data()['user_id']).get();

        widget.userFeed.add(FeedItemModel(
          id: element.id,
          profileName: activityData.data()["user_name"],
          activityTitle: activityData.data()["title"],
          activityDescription: activityData.data()["description"],
          imageUrl: activityData.data()['image_url'],
          avatarUrl: userData.data()['image_url'],
          type: element.data()['type'],
          dateTime: DateTime.parse(element.data()['date_time']),
          coordinates: activityData.data()['coordinates'],
          likes: likesUsersDocsList.length - 1,
          likesUsers: likesUsersDocsList,
          currentUserLike: likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid),
          distance: activityData.data()['distance_meters'],
          duration: activityData.data()['duration_seconds'],
          userId: activityData.data()['user_id'],
          parentId: activityData.id,
          comments: element.data()['number_comments'],
        ));
      } else if (element.data()['type'] == "help") {
        final helpRequestData = await FirebaseFirestore.instance.collection('help_request').doc(element.data()['help_request_id']).get();
        final userData = await FirebaseFirestore.instance.collection('users').doc(helpRequestData.data()['user_id']).get();
        widget.userFeed.add(FeedItemModel(
          id: element.id,
          profileName: helpRequestData.data()['user_name'],
          activityTitle: helpRequestData.data()['title'],
          activityDescription: helpRequestData.data()['description'],
          imageUrl: helpRequestData.data()['image_url'],
          avatarUrl: userData.data()['image_url'],
          type: element.data()['type'],
          dateTime: DateTime.parse(element.data()['date_time']),
          userId: helpRequestData.data()['user_id'],
          parentId: helpRequestData.id,
          latitude: helpRequestData.data()['latitude'],
          longitude: helpRequestData.data()['longitude'],
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData = fetchData(widget.userId, true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _fetchData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            return widget.userFeed.length == 0
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      widget.username + " ainda não fez nenhuma publicação",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: widget.userFeed.length,
                        itemBuilder: (BuildContext context, int i) {
                          return Container(
                            key: UniqueKey(),
                            child: FeedCard(item: widget.userFeed[i], notifyParent: widget.refresh),
                          );
                        },
                      ),
                      widget.showEndButton
                          ? widget.lastFeedItem
                              ? Container(
                                  margin: EdgeInsets.only(bottom: 15),
                                  child: Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("Você chegou ao fim (:"),
                                    ),
                                  ),
                                )
                              : Container(
                                  margin: EdgeInsets.only(bottom: 15),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        widget.showEndButton = false;
                                        widget.endScreenLoading = true;
                                      });
                                      await fetchData(widget.userId, false);
                                      setState(() {
                                        widget.showEndButton = true;
                                        widget.endScreenLoading = false;
                                      });
                                    },
                                    child: Text('Mostrar mais'),
                                  ),
                                )
                          : widget.lastFeedItem
                              ? Container(
                                  margin: EdgeInsets.only(bottom: 15),
                                  child: Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("Você chegou ao fim (:"),
                                    ),
                                  ),
                                )
                              : Container(),
                      widget.endScreenLoading
                          ? Container(
                              child: CircularProgressIndicator(),
                              margin: EdgeInsets.only(bottom: 100, top: 25),
                            )
                          : Container(),
                    ],
                  );
          }
          return Container();
        });
  }
}
