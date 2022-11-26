import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobi/backoffice/utils.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<QueryDocumentSnapshot> userActivities = [];
  double distanceMeters = 0;
  int timeSeconds = 0;
  int activityCount = 0;
  int alertCount = 0;
  int usersHelped = 0;
  Duration timeDuration;
  String periodValue = 'Todo o período';

  Future<DocumentSnapshot> fetchStatistics(String period) async {
    distanceMeters = 0;
    timeSeconds = 0;
    activityCount = 0;
    alertCount = 0;
    usersHelped = 0;
    DateTime currentDateTime = DateTime.now();
    DateTime limitDateTime;
    QuerySnapshot activitiesCollection;
    QuerySnapshot alertsCollection;
    QuerySnapshot helpRequestsCollection;

    switch (period) {
      case 'Todo o período':
        activitiesCollection = await FirebaseFirestore.instance
            .collection('activities')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .get();
        alertsCollection =
            await FirebaseFirestore.instance.collection('alerts').where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid).get();
        helpRequestsCollection = await FirebaseFirestore.instance
            .collection('help_request')
            .where('provider_user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .get();
        break;

      case 'Última semana':
        limitDateTime = currentDateTime.subtract(Duration(days: 7));
        activitiesCollection = await FirebaseFirestore.instance
            .collection('activities')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time', isGreaterThan: limitDateTime)
            .get();
        alertsCollection = await FirebaseFirestore.instance
            .collection('alerts')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time', isGreaterThan: limitDateTime)
            .get();
        helpRequestsCollection = await FirebaseFirestore.instance
            .collection('help_request')
            .where('provider_user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time_closed', isGreaterThan: limitDateTime)
            .get();
        break;

      case 'Último mês':
        limitDateTime = currentDateTime.subtract(Duration(days: 30));
        activitiesCollection = await FirebaseFirestore.instance
            .collection('activities')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time', isGreaterThan: limitDateTime)
            .get();
        alertsCollection = await FirebaseFirestore.instance
            .collection('alerts')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time', isGreaterThan: limitDateTime)
            .get();
        helpRequestsCollection = await FirebaseFirestore.instance
            .collection('help_request')
            .where('provider_user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time_closed', isGreaterThan: limitDateTime)
            .get();
        break;

      case 'Último ano':
        limitDateTime = currentDateTime.subtract(Duration(days: 365));
        activitiesCollection = await FirebaseFirestore.instance
            .collection('activities')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time', isGreaterThan: limitDateTime)
            .get();
        alertsCollection = await FirebaseFirestore.instance
            .collection('alerts')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time', isGreaterThan: limitDateTime)
            .get();
        helpRequestsCollection = await FirebaseFirestore.instance
            .collection('help_request')
            .where('provider_user_id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
            .where('date_time_closed', isGreaterThan: limitDateTime)
            .get();
        break;
    }

    List<QueryDocumentSnapshot> activitiesDocs = activitiesCollection.docs;
    List<QueryDocumentSnapshot> alertsDocs = alertsCollection.docs;
    List<QueryDocumentSnapshot> helpRequestsDocs = helpRequestsCollection.docs;

    activitiesDocs.forEach((element) async {
      distanceMeters += element.data()['distance_meters'];
      timeSeconds += element.data()['duration_seconds'];
      timeDuration = new Duration(seconds: timeSeconds);
    });

    activityCount += activitiesDocs.length;
    alertCount += alertsDocs.length;
    usersHelped += helpRequestsDocs.length;

    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).get();
    return userSnapshot;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estatísticas'),
      ),
      body: FutureBuilder(
        future: fetchStatistics(periodValue),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            var user = snapshot.data.data();

            // Calculates the user level
            var experience = user['experience'];
            var experienceTemp = experience;
            var level = 0;
            var xpToNextLevel = 0;
            while (experienceTemp >= 0) {
              xpToNextLevel += (level + 1) * 100;
              experienceTemp -= (level + 1) * 100;
              level++;
            }

            return Container(
              child: Column(
                children: <Widget>[
                  DropdownButton(
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
                  Card(
                    elevation: 4,
                    margin: EdgeInsets.only(top: 15, left: 30, right: 30),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        child: Column(
                          children: [
                            Column(
                              children: [
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
                                      child: Text(
                                        'Nível $level',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Text("Experiência atual: ${experience}XP"),
                                Text("Próximo nível: ${xpToNextLevel}XP"),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Distância total "),
                                    Text("CO2 nao emitido "),
                                    Text("Tempo total "),
                                    Text("Atividades registradas "),
                                    Text("Alertas criados "),
                                    Text("Pedidos de ajuda atentidos "),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text((distanceMeters / 1000).toStringAsFixed(2) + 'km'),
                                    Text((distanceMeters / 1000 * 0.25).toStringAsFixed(2) + 'kg'),
                                    Text(printDuration(timeDuration, true)),
                                    Text(activityCount.toString()),
                                    Text(alertCount.toString()),
                                    Text(usersHelped.toString()),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        )),
                  ),
                  Spacer(),
                  Image.asset(
                    'lib/assets/images/bike_background.png',
                    scale: 2,
                  ),
                ],
              ),
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
