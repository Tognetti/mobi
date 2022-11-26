import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/widgets/feed_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobi/models/feed_item_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';


class Feed extends StatefulWidget {
  Feed({Key key}) : super(key: key);

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  List<FeedItemModel> _feedItems = [];
  FeedItemModel helpFeedItem;
  Set<Marker> _markers = {};
  Future<void> _fetchData;
  bool onlyFollowing = false;
  bool isLoading = false;
  bool helpRequestCard = false;
  bool showActivityFeed = true;
  bool showAlertsFeed = true;
  bool showHelpFeed = true;
  bool showOnlyFriendsFeed = false;
  List<QueryDocumentSnapshot> feedItemCollectionDocs = [];
  bool endScreenLoading = false;
  bool lastFeedItem = false;
  bool showEndButton = true;
  List followingUsersIds = [];
  List<QueryDocumentSnapshot> newFeedItemsDocs;

  Future<void> fetchData(bool firstFetch) async {
    QuerySnapshot feedItemCollection;
    List typesQuery = [];

    final currentUserData = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).get();
    if (currentUserData.data() != null) {
      showActivityFeed = currentUserData.data()['show_activity_feed'] ?? true;
      showAlertsFeed = currentUserData.data()['show_alerts_feed'] ?? true;
      showHelpFeed = currentUserData.data()['show_help_feed'] ?? true;
      showOnlyFriendsFeed = currentUserData.data()['show_only_friends_feed'] ?? false;
    }

    if (showActivityFeed) {
      typesQuery.add('activity');
    }
    if (showAlertsFeed) {
      typesQuery.add('alert');
    }
    if (showHelpFeed) {
      typesQuery.add('help');
    }

    Query baseQuery;
    if (typesQuery.isNotEmpty) {
      if (showOnlyFriendsFeed) {
        baseQuery = FirebaseFirestore.instance
            .collection('users/${FirebaseAuth.instance.currentUser.uid}/feed_item')
            .where('active', isEqualTo: true)
            .where('type', whereIn: typesQuery)
            .orderBy('date_time', descending: true);
      } else {
        baseQuery = FirebaseFirestore.instance
            .collection('feed_item')
            .where('active', isEqualTo: true)
            .where('type', whereIn: typesQuery)
            .orderBy('date_time', descending: true);
      }

      if (firstFetch) {
        _feedItems = [];

        feedItemCollection = await baseQuery.limit(5).get();
        newFeedItemsDocs = feedItemCollection.docs;
        feedItemCollectionDocs = feedItemCollection.docs;
      } else {
        if (feedItemCollectionDocs.isNotEmpty) {
          feedItemCollection = await baseQuery.startAfterDocument(feedItemCollectionDocs.last).limit(5).get();
          newFeedItemsDocs = feedItemCollection.docs;
          feedItemCollectionDocs.addAll(newFeedItemsDocs);
        }
      }

      if (feedItemCollection != null && feedItemCollection.size == 0) {
        lastFeedItem = true;
        showEndButton = false;
        return;
      }

      for (var element in newFeedItemsDocs) {
        var generalFeedItemData;
        if (showOnlyFriendsFeed) {
          generalFeedItemData = await FirebaseFirestore.instance.collection('feed_item').doc(element.data()['general_feed_item_id']).get();
        } else {
          generalFeedItemData = element;
        }

        final likesUsersDocs = await generalFeedItemData.reference.collection('likes_users').get();
        final likesUsersDocsList = likesUsersDocs.docs.toList();
        final likesUsersDocsListIds = likesUsersDocsList.map((e) => e.id);

        if (generalFeedItemData.data()['type'] == "alert" && showAlertsFeed) {
          final alertData = await FirebaseFirestore.instance.collection('alerts').doc(generalFeedItemData.data()['alert_id']).get();
          final userData = await FirebaseFirestore.instance.collection('users').doc(alertData.data()['user_id']).get();

          _feedItems.add(FeedItemModel(
            id: generalFeedItemData.id,
            profileName: alertData.data()['user_name'],
            activityTitle: alertData.data()['title'],
            activityDescription: alertData.data()['description'],
            imageUrl: alertData.data()['image_url'],
            avatarUrl: userData.data()['image_url'],
            type: generalFeedItemData.data()['type'],
            dateTime: DateTime.parse(generalFeedItemData.data()['date_time']),
            likes: likesUsersDocsList.length - 1,
            likesUsers: likesUsersDocsList,
            currentUserLike: likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid),
            userId: alertData.data()['user_id'],
            parentId: alertData.id,
            comments: generalFeedItemData.data()['number_comments'],
            latitude: alertData.data()['latitude'],
            longitude: alertData.data()['longitude'],
          ));
        } else if (generalFeedItemData.data()['type'] == "activity" && showActivityFeed) {
          final activityData =
              await FirebaseFirestore.instance.collection('activities').doc(generalFeedItemData.data()['activity_id']).get();
          final userData = await FirebaseFirestore.instance.collection('users').doc(activityData.data()['user_id']).get();

          _feedItems.add(FeedItemModel(
            id: generalFeedItemData.id,
            profileName: activityData.data()["user_name"],
            activityTitle: activityData.data()["title"],
            activityDescription: activityData.data()["description"],
            imageUrl: activityData.data()['image_url'],
            avatarUrl: userData.data()['image_url'],
            type: generalFeedItemData.data()['type'],
            dateTime: DateTime.parse(generalFeedItemData.data()['date_time']),
            coordinates: activityData.data()['coordinates'],
            likes: likesUsersDocsList.length - 1,
            likesUsers: likesUsersDocsList,
            currentUserLike: likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid),
            distance: activityData.data()['distance_meters'],
            duration: activityData.data()['duration_seconds'],
            userId: activityData.data()['user_id'],
            parentId: activityData.id,
            comments: generalFeedItemData.data()['number_comments'],
          ));
        } else if (generalFeedItemData.data()['type'] == "help" && showHelpFeed) {
          final helpRequestData =
              await FirebaseFirestore.instance.collection('help_request').doc(generalFeedItemData.data()['help_request_id']).get();
          final userData = await FirebaseFirestore.instance.collection('users').doc(helpRequestData.data()['user_id']).get();

          if (helpRequestData.data()['active'] == true) {
            _feedItems.add(FeedItemModel(
              id: generalFeedItemData.id,
              profileName: helpRequestData.data()['user_name'],
              activityTitle: helpRequestData.data()['title'],
              activityDescription: helpRequestData.data()['description'],
              imageUrl: helpRequestData.data()['image_url'],
              avatarUrl: userData.data()['image_url'],
              type: generalFeedItemData.data()['type'],
              dateTime: DateTime.parse(generalFeedItemData.data()['date_time']),
              userId: helpRequestData.data()['user_id'],
              parentId: helpRequestData.id,
              latitude: helpRequestData.data()['latitude'],
              longitude: helpRequestData.data()['longitude'],
            ));
          }
        }
      }
    } else {
      lastFeedItem = true;
      showEndButton = false;
    }

    // Verifica se o user atual possui um pedido de ajuda ativo
    if (firstFetch) {
      QuerySnapshot helpRequestSnapshot = await FirebaseFirestore.instance
          .collection('help_request')
          .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
          .where('active', isEqualTo: true)
          .get();
      if (helpRequestSnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot helpRequestDoc = helpRequestSnapshot.docs.first;

        DocumentSnapshot feedItemDoc =
            await FirebaseFirestore.instance.collection('feed_item').doc(helpRequestDoc.data()['feed_item_id']).get();

        helpFeedItem = FeedItemModel(
          id: feedItemDoc.id,
          profileName: helpRequestDoc.data()['user_name'],
          activityTitle: helpRequestDoc.data()['title'],
          activityDescription: helpRequestDoc.data()['description'],
          imageUrl: helpRequestDoc.data()['image_url'],
          avatarUrl: currentUserData.data()['image_url'],
          type: feedItemDoc.data()['type'],
          dateTime: DateTime.parse(feedItemDoc.data()['date_time']),
          userId: helpRequestDoc.data()['user_id'],
          parentId: helpRequestDoc.id,
          latitude: helpRequestDoc.data()['latitude'],
          longitude: helpRequestDoc.data()['longitude'],
        );

        helpRequestCard = true;
        BitmapDescriptor helpIcon =
            await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 1), 'lib/assets/images/help_icon.png');
        _markers.add(Marker(
          markerId: MarkerId('1'),
          position: LatLng(helpRequestDoc.data()['latitude'], helpRequestDoc.data()['longitude']),
          icon: helpIcon,
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData = fetchData(true);
    WidgetsBinding.instance.addPostFrameCallback((_){
      getPermissions();
    });
  }

  Future<void> refresh() async {
    setState(() {
      isLoading = true;
      showEndButton = false;
    });
    _feedItems = [];
    feedItemCollectionDocs = [];
    helpRequestCard = false;
    lastFeedItem = false;
    await fetchData(true);
    setState(() {
      isLoading = false;
      showEndButton = true;
    });
  }

  var location = new Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;



  void getPermissions() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();


      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    location.enableBackgroundMode(enable: true);

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
          return RefreshIndicator(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: EdgeInsets.only(right: 10),
                      child: IconButton(
                        color: Colors.green,
                        iconSize: 30,
                        icon: Icon(Icons.settings),
                        onPressed: () async {
                          final doRefresh =
                              await showMyDialogFeedSettings(context, showOnlyFriendsFeed, showActivityFeed, showAlertsFeed, showHelpFeed);
                          if (doRefresh == true) {
                            refresh();
                          }
                        },
                      ),
                    ),
                  ),
                  helpRequestCard && !isLoading
                      ? InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/help_card_details', arguments: [helpFeedItem, _markers]);
                          },
                          child: Card(
                            elevation: 3,
                            margin: EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 10),
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
                                      "Você possui um pedido de ajuda ativo!",
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(),
                  isLoading ? SizedBox(height: 200) : Container(),
                  isLoading
                      ? Container(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _feedItems.length,
                            itemBuilder: (BuildContext context, int i) {
                              return Container(
                                key: UniqueKey(),
                                child: FeedCard(item: _feedItems[i], notifyParent: refresh),
                              );
                            },
                          ),
                        ),
                  showEndButton
                      ? lastFeedItem
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
                                    showEndButton = false;
                                    endScreenLoading = true;
                                  });
                                  await fetchData(false);
                                  setState(() {
                                    showEndButton = true;
                                    endScreenLoading = false;
                                  });
                                },
                                child: Text('Mostrar mais'),
                              ),
                            )
                      : lastFeedItem
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
                  endScreenLoading
                      ? Container(
                          child: CircularProgressIndicator(),
                          margin: EdgeInsets.only(bottom: 100),
                        )
                      : Container(),
                ],
              ),
            ),
            onRefresh: refresh,
          );
        }
        return null;
      },
    );
  }
}
