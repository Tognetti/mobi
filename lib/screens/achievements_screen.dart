import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobi/models/achievements_model.dart';
import 'package:mobi/widgets/all_achievements.dart';
import 'package:mobi/widgets/user_achievements.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementsScreen extends StatefulWidget {
  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  var _selectedIndex = 0;
  Future<void> _fetchAchievements;
  final List<AchievementModel> _allAchievements = [];
  final List<AchievementModel> _userAchievements = [];
  List<Widget> _widgetOptions;

  Future<void> fetchAchievements() async {
    final allAchievementsCollection = await FirebaseFirestore.instance.collection('achievements').orderBy('name').get();
    final userAchievementsCollection =
        await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/user_achievements').get();
    for (var element in allAchievementsCollection.docs) {
      var achievementData = element.data();
      _allAchievements.add(AchievementModel(
        id: element.id,
        imageUrl: achievementData['image_url'],
        description: achievementData['description'],
        name: achievementData['name'],
        target: achievementData['target'],
      ));
    }
    for (var element in userAchievementsCollection.docs) {
      if (element.id != 'dummy_achievement') {
        var userAchievementData = element.data();
        var achievementData = _allAchievements.firstWhere((e) => e.id == element.id);

        _userAchievements.add(AchievementModel(
          id: achievementData.id,
          imageUrl: achievementData.imageUrl,
          description: achievementData.description,
          name: achievementData.name,
          target: achievementData.target,
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAchievements = fetchAchievements();
    _widgetOptions = <Widget>[
      UserAchievements(_userAchievements, _allAchievements),
      AllAchievements(_allAchievements),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _fetchAchievements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return _widgetOptions.elementAt(_selectedIndex);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            title: Text("Minhas conquistas"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_rounded),
            title: Text("Todas as conquistas"),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
