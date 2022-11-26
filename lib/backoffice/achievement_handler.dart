import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AchievementEnum {
  static const String DISTANCE_1 = '2ZrrCRmwVnXqI4CFqsUu';
  static const String DISTANCE_2 = 'BAqQnvxVQ7jy0urG3bGJ';
  static const String DISTANCE_3 = 'JQ5QSo9nfuQj80CXJqAQ';
  static const String ACTIVITY_TIME_1 = '5jaITrNgAZVtcbb9HzZf';
  static const String ACTIVITY_TIME_2 = 'av69ypS60eIiFL1Jl2Pk';
  static const String ACTIVITY_TIME_3 = 'Cy5Iyk8GKrV95hafIcYZ';
  static const String PARTICIPATING_IN_COMMUNITY = '8Z5AODQRX96B5soORE4O';
  static const String ACTIVITY_LOG_1 = 'CS7itKvEOnotAURecdNV';
  static const String ACTIVITY_LOG_2 = 'BRVMlg1wvaXEhju5o4UA';
  static const String ACTIVITY_LOG_3 = 'gSgxkaic69TVsZxlGvov';
  static const String ALERT_CREATION_1 = 'd3wAh6hapvZA7bxuFrvD';
  static const String ALERT_CREATION_2 = 'n64wQliu5TeCPzFREAm0';
  static const String ALERT_CREATION_3 = 'JaaMdweXSNP6sJow4Z6A';
  static const String SAVING_THE_DAY = 'Ox862h7qE5CodzkS8Zud';
}

enum Statistic { distance_ridden, activity_time, activity_count, users_followed, alert_count, users_helped, total_co2_saved }

var achievementStatistics = {
  Statistic.distance_ridden: [AchievementEnum.DISTANCE_1, AchievementEnum.DISTANCE_2, AchievementEnum.DISTANCE_3],
  Statistic.activity_time: [AchievementEnum.ACTIVITY_TIME_1, AchievementEnum.ACTIVITY_TIME_2, AchievementEnum.ACTIVITY_TIME_3],
  Statistic.activity_count: [AchievementEnum.ACTIVITY_LOG_1, AchievementEnum.ACTIVITY_LOG_2, AchievementEnum.ACTIVITY_LOG_3],
  Statistic.users_followed: [AchievementEnum.PARTICIPATING_IN_COMMUNITY],
  Statistic.alert_count: [AchievementEnum.ALERT_CREATION_1, AchievementEnum.ALERT_CREATION_2, AchievementEnum.ALERT_CREATION_3],
  Statistic.users_helped: [AchievementEnum.SAVING_THE_DAY]
};

class AchievementHandler {
  static Future<void> updateStat(String userId, Statistic stat, num value, BuildContext snackbarContext) async {
    var statisticDoc = await FirebaseFirestore.instance.collection('users/$userId/statistics').doc(describeEnum(stat)).get();

    if (statisticDoc.exists) {
      var statisticData = statisticDoc.data();
      var currentValue = statisticData['value'];
      var newValue = currentValue + value;
      FirebaseFirestore.instance
          .collection('users/$userId/statistics')
          .doc(describeEnum(stat))
          .update({'value': newValue}).then((value) => checkAchievementProgress(userId, stat, newValue, snackbarContext));
    }
  }

  static Future<void> checkAchievementProgress(String userId, Statistic stat, num newValue, BuildContext snackbarContext) async {
    for (var achievement in achievementStatistics[stat]) {
      var userAchievementDoc = await FirebaseFirestore.instance.collection('users/$userId/user_achievements').doc(achievement).get();

      if (userAchievementDoc.exists) {
        continue;
      }

      var achievementTemplateDoc = await FirebaseFirestore.instance.collection('achievements').doc(achievement).get();

      var achievementTemplateData = achievementTemplateDoc.data();
      if (achievementTemplateData['target'] <= newValue) {
        winAchievement(userId, achievement, achievementTemplateData, snackbarContext, achievementTemplateDoc);
        winExperience(userId, achievementTemplateData);
      }
    }
  }

  static Future<void> winExperience(String userId, Map<String, dynamic> achievementTemplateData) async {
    var userData = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    var previousExperience = userData.data()['experience'];
    var newExperience = achievementTemplateData['experience'];

    await FirebaseFirestore.instance.collection('users').doc(userId).update({'experience': previousExperience + newExperience});
  }

  static void winAchievement(String userId, String achievement, Map<String, dynamic> achievementTemplateData, BuildContext snackbarContext,
      DocumentSnapshot achievementTemplateDoc) {
    FirebaseFirestore.instance.collection('users/$userId/user_achievements').doc(achievement).set(achievementTemplateData).then(
      (value) {
        if (FirebaseAuth.instance.currentUser.uid == userId) {
          ScaffoldMessenger.of(snackbarContext).showSnackBar(
            SnackBar(
              content: Container(
                height: 100,
                child: Row(
                  children: [
                    Image.network(
                      achievementTemplateDoc.data()['image_url'],
                      height: 80,
                      width: 80,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Você desbloqueou uma conquista!"),
                        SizedBox(height: 10),
                        Text(achievementTemplateDoc.data()['name']),
                        SizedBox(height: 10),
                        Text('+ ' + achievementTemplateDoc.data()['experience'].toString() + 'XP'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
