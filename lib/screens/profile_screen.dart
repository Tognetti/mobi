import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/models/achievements_model.dart';
import 'package:mobi/widgets/profile_appbar.dart';
import 'package:mobi/models/feed_item_model.dart';
import 'package:mobi/widgets/profile_screen_feed.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<AchievementModel> _userAchievements = [];
  final List<AchievementModel> _allAchievements = [];
  FeedItemModel helpFeedItem;
  List<FeedItemModel> _userFeed = [];
  bool isFollowing = false;
  bool helpRequestCard = false;
  Set<Marker> _markers = {};
  int usersHelped = 0;
  List<QueryDocumentSnapshot> feedItemCollectionDocs = [];
  List<QueryDocumentSnapshot> newFeedItemsDocs;
  bool lastFeedItem = false;
  bool showEndButton = true;
  bool endScreenLoading = false;
  int numberFollowers;
  int numberFollowing;

  Future<void> refresh() async {
    setState(() {
      showEndButton = false;
    });
    _userFeed = [];
    setState(() {
      showEndButton = true;
    });
  }

  Future<DocumentSnapshot> fetchData(userId, bool firstFetch) async {
    _userAchievements.clear();

    final allAchievementsCollection = await FirebaseFirestore.instance.collection('achievements').orderBy('name').get();
    final userAchievementsCollection = await FirebaseFirestore.instance.collection('users/$userId/user_achievements').get();
    final usersHelpedCollection = await FirebaseFirestore.instance.collection('users/$userId/statistics/').doc('users_helped').get();
    usersHelped = usersHelpedCollection.data()['value'];
    final currentUserFollowingCollection = await FirebaseFirestore.instance.collection('users/$userId/following_users').get();
    numberFollowing = currentUserFollowingCollection.docs.length - 1;
    final currentUserFollowersCollection = await FirebaseFirestore.instance.collection('users/$userId/followers_users').get();
    numberFollowers = currentUserFollowersCollection.docs.length - 1;

    for (var element in currentUserFollowingCollection.docs) {
      if (element.id == userId) {
        isFollowing = true;
        break;
      }
    }

    for (var element in allAchievementsCollection.docs) {
      _allAchievements.add(AchievementModel(
        id: element.id,
        imageUrl: element.data()['image_url'],
        description: element.data()['description'],
        name: element.data()['name'],
        target: element.data()['target'],
      ));
    }

    for (var element in userAchievementsCollection.docs) {
      if (element.id != 'dummy_achievement') {
        var achievementData = _allAchievements.firstWhere((e) => e.id == element.id);
        _userAchievements.add(AchievementModel(
            id: achievementData.id,
            imageUrl: achievementData.imageUrl,
            description: achievementData.description,
            name: achievementData.name,
            target: achievementData.target));
      }
    }

    // Verifica se o user atual possui um pedido de ajuda ativo
    if (firstFetch) {
      QuerySnapshot helpRequestSnapshot = await FirebaseFirestore.instance
          .collection('help_request')
          .where('user_id', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .get();
      if (helpRequestSnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot helpRequestDoc = helpRequestSnapshot.docs.first;

        DocumentSnapshot feedItemDoc =
            await FirebaseFirestore.instance.collection('feed_item').doc(helpRequestDoc.data()['feed_item_id']).get();
        final userData = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        helpFeedItem = FeedItemModel(
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

    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  @override
  Widget build(BuildContext context) {
    String userId = ModalRoute.of(context).settings.arguments;

    return FutureBuilder(
      future: fetchData(userId, true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Perfil"),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          var user = snapshot.data.data();

          // Calculates the user level
          var experience = user['experience'];
          var level = 0;
          while (experience >= 0) {
            experience -= (level + 1) * 100;
            level++;
          }

          return Scaffold(
            appBar: ProfileAppBar(isFollowing, userId, refresh),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("lib/assets/images/background.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    width: double.infinity,
                    height: 300,
                    child: Center(
                      child: Container(
                        width: 300,
                        height: 290,
                        child: Card(
                          color: Color.fromRGBO(255, 255, 255, 0.825),
                          elevation: 20,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(user['image_url']),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      user['username'],
                                      style: TextStyle(fontSize: 23),
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Card(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: Colors.green, width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    color: Colors.green,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Container(
                                        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        child: level == 0
                                            ? Text(
                                                'Nível 1',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'Nível $level',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    user['cidade'] + ", " + user['estado'],
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(context, '/followers_screen', arguments: userId);
                                        },
                                        child: Text(
                                          '$numberFollowers seguidores | ',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(context, '/following_screen', arguments: userId);
                                        },
                                        child: Text(
                                          '$numberFollowing seguindo',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              FirebaseAuth.instance.currentUser.uid == userId
                                  ? Container()
                                  : IconButton(
                                      icon: new Icon(Icons.mail),
                                      color: Colors.green,
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/chat', arguments: [userId, user['username'], user['image_url']]);
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  (FirebaseAuth.instance.currentUser.uid != userId) && (helpRequestCard == true)
                      ? InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/help_card_details', arguments: [helpFeedItem, _markers]);
                          },
                          child: Card(
                            elevation: 3,
                            margin: EdgeInsets.only(top: 15, left: 20, right: 20),
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
                                      "${user['username']} possui um pedido de ajuda ativo!",
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(),
                  usersHelped == 0
                      ? Container()
                      : Card(
                          elevation: 3,
                          margin: EdgeInsets.only(top: 15, left: 20, right: 20),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                            child: Row(
                              children: [
                                Image.asset(
                                  'lib/assets/images/handshake_icon.png',
                                  scale: 3.5,
                                ),
                                SizedBox(width: 10),
                                usersHelped == 1
                                    ? Flexible(
                                        child: Text(
                                          "${user['username']} já ajudou 1 pessoa pelo Mobi!",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      )
                                    : Flexible(
                                        child: Text(
                                          "${user['username']} já ajudou $usersHelped pessoas pelo Mobi!",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      )
                              ],
                            ),
                          ),
                        ),
                  Container(
                    margin: EdgeInsets.only(top: 15),
                    child: Text(
                      "Conquistas",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  Container(
                    child: _userAchievements.length == 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              user['username'] + " ainda não possui nenhuma conquista",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                            ),
                            itemCount: _userAchievements.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, int i) {
                              return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return Container(
                                        height: 220,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 15),
                                          child: Column(
                                            children: <Widget>[
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 15),
                                                child: Image.network(
                                                  _userAchievements[i].getImageUrl,
                                                  height: 120,
                                                  width: 120,
                                                ),
                                              ),
                                              Text(
                                                _userAchievements[i].getName,
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  _userAchievements[i].getDescription,
                                                  style: TextStyle(fontSize: 17),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.all(15),
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(child: Image.network(_userAchievements[i].getImageUrl)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Column(
                    children: [
                      Text(
                        "Atividades",
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      ProfileFeed(user['username'], _userFeed, refresh, showEndButton, lastFeedItem, endScreenLoading, userId,
                          feedItemCollectionDocs),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}
