import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mobi/components/navigation/navigation_drawer.dart';
import 'package:mobi/screens/achievements_screen.dart';
import 'package:mobi/screens/alert_screen.dart';
import 'package:mobi/screens/feed.dart';
import 'package:mobi/screens/activity_screen.dart';
import 'package:mobi/screens/help_create_map_screen.dart';
import 'package:mobi/screens/ranking_screen.dart';
import 'package:mobi/screens/show_map_screen.dart';
import 'package:mobi/screens/statistics_screen.dart';

const double _textAndIconTabHeight = 40.0;

class TabNavigationBar extends StatefulWidget {
  @override
  _TabNavigationBarState createState() => _TabNavigationBarState();
}

class _TabNavigationBarState extends State<TabNavigationBar> {
  Future<DocumentSnapshot> _fetchData;
  // String username = "";
  // String userImageUrl = "";
  int unreadNumber;
  QuerySnapshot unreadConversationsDocs;

  Future<DocumentSnapshot> fetchData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).get();
    return userDoc;
    // username = userDoc.data()['username'];
    // userImageUrl = userDoc.data()['image_url'];
  }

  @override
  void initState() {
    super.initState();
    _fetchData = fetchData();
  }

  Future<void> refresh() async {
    await fetchData();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: ColoredTabBar(
              Colors.white,
              TabBar(
                indicatorColor: Colors.lightGreen,
                labelColor: Colors.lightGreen,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(child: Text("Feed")),
                  Tab(child: Text("Rankings")),
                  Tab(child: Text("Conquistas")),
                ],
              )),
          title: Text("Mobi"),
          actions: [
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations/')
                  .where('unread', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: IconButton(
                      icon: Icon(Icons.mail),
                      onPressed: () {
                        Navigator.pushNamed(context, '/conversations').then((value) => refresh());
                      },
                    ),
                  );
                }
                if (snapshot.hasData) {
                  final docs = snapshot.data.docs;
                  unreadNumber = docs.length;
                  return Stack(
                    children: <Widget>[
                      new IconButton(
                        icon: Icon(Icons.mail),
                        onPressed: () {
                          Navigator.pushNamed(context, '/conversations').then((value) => refresh());
                        },
                      ),
                      unreadNumber != 0
                          ? new Positioned(
                              right: 5,
                              top: 8,
                              child: new Container(
                                padding: EdgeInsets.all(2),
                                decoration: new BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '$unreadNumber',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : new Container()
                    ],
                  );
                }
                return Container(
                  child: CircularProgressIndicator(),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              // onPressed: () async {
              //   showSearch(
              //     context: context,
              //     delegate: Search(),
              //   );
              // },
              onPressed: () {
                Navigator.pushNamed(context, '/search_user').then((value) => refresh());
              },
            )
          ],
        ),
        drawer: NavDrawer(refresh),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            Feed(),
            RankingScreen(),
            AchievementsScreen(),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: SpeedDial(
            child: Icon(Icons.list),
            buttonSize: 60,
            spacing: 5,
            spaceBetweenChildren: 5,
            children: [
              SpeedDialChild(
                label: 'Mapa de alertas e pedidos',
                labelBackgroundColor: Color(0xdcdada).withOpacity(1),
                child: Image.asset(
                  'lib/assets/images/map_icon.png',
                  scale: 1,
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/show_map_screen');
                },
              ),
              SpeedDialChild(
                label: 'Registrar atividade',
                labelBackgroundColor: Color(0xdcdada).withOpacity(1),
                child: Image.asset(
                  'lib/assets/images/activity_icon.png',
                  scale: 1,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityScreen()));
                },
              ),
              SpeedDialChild(
                label: 'Criar pedido de ajuda',
                labelBackgroundColor: Color(0xdcdada).withOpacity(1),
                child: Image.asset(
                  'lib/assets/images/help_icon.png',
                  scale: 1,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HelpMapScreen()));
                },
              ),
              SpeedDialChild(
                label: 'Criar alerta',
                labelBackgroundColor: Color(0xdcdada).withOpacity(1),
                child: Image.asset(
                  'lib/assets/images/alert_icon.png',
                  scale: 1,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AlertScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColoredTabBar extends Container implements PreferredSizeWidget {
  ColoredTabBar(this.color, this.tabBar);

  final Color color;
  final TabBar tabBar;

  @override
  Size get preferredSize => Size.fromHeight(_textAndIconTabHeight + tabBar.indicatorWeight);

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        child: tabBar,
      );
}
