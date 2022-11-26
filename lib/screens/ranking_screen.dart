import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobi/backoffice/utils.dart';

class RankingScreen extends StatefulWidget {
  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String periodValue = 'Todo o período';
  String categoryValue = 'Nível';
  List<Map> users = [];
  Map currentUser;
  int currentUserIndex;

  Future<List<Map>> getUsers(period, category) async {
    users = [];
    QuerySnapshot activitiesCollection;
    QuerySnapshot usersCollection;
    DateTime currentDateTime = DateTime.now();
    DateTime limitDateTime;

    if (category == 'Nível') {
      usersCollection = await FirebaseFirestore.instance.collection('users').get();
      List<QueryDocumentSnapshot> usersDocs = usersCollection.docs;

      usersDocs.forEach((user) {
        users.add({
          'user_image': user.data()['image_url'],
          'user_id': user.id,
          'user_name': user.data()['username'],
          'experience': user.data()['experience'],
        });
      });
    } else {
      switch (period) {
        case 'Todo o período':
          activitiesCollection = await FirebaseFirestore.instance.collection('activities').get();
          break;
        case 'Última semana':
          limitDateTime = currentDateTime.subtract(Duration(days: 7));
          activitiesCollection =
              await FirebaseFirestore.instance.collection('activities').where('date_time', isGreaterThan: limitDateTime).get();
          break;
        case 'Último mês':
          limitDateTime = currentDateTime.subtract(Duration(days: 30));
          activitiesCollection =
              await FirebaseFirestore.instance.collection('activities').where('date_time', isGreaterThan: limitDateTime).get();
          break;
        case 'Último ano':
          limitDateTime = currentDateTime.subtract(Duration(days: 365));
          activitiesCollection =
              await FirebaseFirestore.instance.collection('activities').where('date_time', isGreaterThan: limitDateTime).get();
          break;
      }

      List<QueryDocumentSnapshot> activitiesDocs = activitiesCollection.docs;

      await Future.forEach(activitiesDocs, (activity) async {
        int index = users.indexWhere((element) => element['user_id'] == activity.data()['user_id']);
        DocumentSnapshot userDocument = await FirebaseFirestore.instance.collection('users').doc(activity.data()['user_id']).get();
        if (index == -1) {
          users.add({
            'user_image': userDocument.data()['image_url'],
            'user_id': activity.data()['user_id'],
            'user_name': activity.data()['user_name'],
            'distance_meters': activity.data()['distance_meters'],
            'duration_seconds': activity.data()['duration_seconds'],
          });
        } else {
          users[index] = {
            'user_image': userDocument.data()['image_url'],
            'user_id': users[index]['user_id'],
            'user_name': users[index]['user_name'],
            'distance_meters': users[index]['distance_meters'] + activity.data()['distance_meters'],
            'duration_seconds': users[index]['duration_seconds'] + activity.data()['duration_seconds'],
          };
        }
      });
    }

    users.sort((a, b) {
      if (category == 'Distância') {
        num distanceA = a['distance_meters'];
        num distanceB = b['distance_meters'];
        return distanceB.compareTo(distanceA);
      } else if (category == 'Tempo') {
        num durationA = a['duration_seconds'];
        num durationB = b['duration_seconds'];
        return durationB.compareTo(durationA);
      } else if (category == 'Nível') {
        num experienceA = a['experience'];
        num experienceB = b['experience'];
        return experienceB.compareTo(experienceA);
      }
      return null;
    });

    currentUserIndex = users.indexWhere((element) => element['user_id'] == FirebaseAuth.instance.currentUser.uid);
    if (currentUserIndex >= 0) {
      currentUser = users[currentUserIndex];
    }

    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      isAlwaysShown: true,
      thickness: 8,
      child: SingleChildScrollView(
        // physics: ScrollPhysics(),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton(
                  value: categoryValue,
                  items: ['Nível', 'Distância', 'Tempo'].map((String value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == 'Nível') {
                      setState(() {
                        periodValue = 'Todo o período';
                      });
                    }
                    setState(() {
                      categoryValue = value;
                    });
                  },
                ),
                SizedBox(width: 20),
                categoryValue == 'Nível'
                    ? DropdownButton(
                        value: periodValue,
                        items: ['Todo o período', 'Última semana', 'Último mês', 'Último ano'].map((String value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: null,
                      )
                    : DropdownButton(
                        value: periodValue,
                        items: ['Todo o período', 'Última semana', 'Último mês', 'Último ano'].map((String value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            periodValue = value;
                          });
                        },
                      ),
              ],
            ),
            SizedBox(height: 15),
            categoryValue == 'Tempo'
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Ranking dos usuários com mais tempo de atividade registrado",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Container(),
            categoryValue == 'Distância'
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Ranking dos usuários com as maiores distâncias percorridas durante as atividades",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Container(),
            categoryValue == 'Nível'
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Ranking dos usuários com os maiores níveis",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Container(),
            SizedBox(height: 15),
            FutureBuilder(
              future: getUsers(periodValue, categoryValue),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  List users = snapshot.data;
                  Duration currentUserTimeDuration;
                  var level;
                  if (currentUserIndex >= 0 && (categoryValue == 'Tempo')) {
                    int timeSeconds = users[currentUserIndex]['duration_seconds'];
                    currentUserTimeDuration = new Duration(seconds: timeSeconds);
                  }

                  if (categoryValue == 'Nível') {
                    // Calculates the user level
                    var experience = users[currentUserIndex]['experience'];
                    level = 0;
                    while (experience >= 0) {
                      experience -= (level + 1) * 100;
                      level++;
                    }
                  }

                  return Column(
                    children: [
                      currentUserIndex >= 0
                          ? Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  width: 200,
                                  child: Column(
                                    children: [
                                      Text(
                                        "Sua posição: ",
                                        style: TextStyle(fontWeight: FontWeight.w400, fontSize: 17),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundImage: NetworkImage(
                                              currentUser['user_image'],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${currentUserIndex + 1}º',
                                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 19),
                                              ),
                                              categoryValue == 'Distância'
                                                  ? Text(
                                                      (currentUser['distance_meters'] / 1000).toStringAsFixed(2) + 'km',
                                                      style: TextStyle(fontWeight: FontWeight.w400, fontSize: 19),
                                                    )
                                                  : Container(),
                                              categoryValue == 'Tempo'
                                                  ? Text(
                                                      printDuration(currentUserTimeDuration, true),
                                                      style: TextStyle(fontWeight: FontWeight.w400, fontSize: 19),
                                                    )
                                                  : Container(),
                                              categoryValue == 'Nível'
                                                  ? Card(
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
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : categoryValue == 'Nível'
                              ? Container()
                              : Card(
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 250,
                                      child: Text(
                                        "Parece que você ainda não registrou nenhuma atividade ):",
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                      SizedBox(height: 15),
                      Container(
                        margin: EdgeInsets.only(bottom: 30),
                        child: ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            int timeSeconds;
                            Duration timeDuration;
                            var level;

                            if (categoryValue == 'Distância' || categoryValue == 'Tempo') {
                              timeSeconds = users[index]['duration_seconds'];
                              timeDuration = new Duration(seconds: timeSeconds);
                            }

                            if (categoryValue == 'Nível') {
                              // Calculates the user level
                              var experience = users[index]['experience'];
                              level = 0;
                              while (experience >= 0) {
                                experience -= (level + 1) * 100;
                                level++;
                              }
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile', arguments: users[index]['user_id']);
                              },
                              child: Container(
                                color: users[index]['user_id'] == FirebaseAuth.instance.currentUser.uid
                                    ? Colors.green.shade100
                                    : Colors.white12,
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        child: Text(
                                          "${index + 1}º",
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
                                        ),
                                        margin: EdgeInsets.only(left: 18),
                                      ),
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: NetworkImage(
                                          users[index]['user_image'],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            users[index]['user_name'],
                                            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                                          ),
                                          categoryValue == 'Distância'
                                              ? Text(
                                                  (users[index]['distance_meters'] / 1000).toStringAsFixed(2) + 'km',
                                                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 19),
                                                )
                                              : Container(),
                                          categoryValue == 'Tempo'
                                              ? Text(
                                                  printDuration(timeDuration, true),
                                                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 19),
                                                )
                                              : Container(),
                                          categoryValue == 'Nível'
                                              ? Card(
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
                                                )
                                              : Container(),
                                          SizedBox(height: 7),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
