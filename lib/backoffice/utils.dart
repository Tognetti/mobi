import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobi/models/feed_item_model.dart';

import 'achievement_handler.dart';

Future<Position> setInitialLocation() async {
  Position initialPosition = await GeolocatorPlatform.instance.getCurrentPosition();
  return initialPosition;
}

String printDuration(Duration duration, bool showSeconds) {
  if (duration != null) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (showSeconds) {
      return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
    } else {
      return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m";
    }
  } else {
    return "0h";
  }
}

Future<void> sendMessage(userId, content) async {
  await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations/$userId/messages').add({
    'content': content,
    'type': 'send',
    'createdAt': Timestamp.now(),
  });
  await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations/').doc('$userId').set({
    'unread': false,
  });
  await FirebaseFirestore.instance.collection('users/$userId/conversations/${FirebaseAuth.instance.currentUser.uid}/messages').add({
    'content': content,
    'type': 'received',
    'createdAt': Timestamp.now(),
  });
  await FirebaseFirestore.instance.collection('users/$userId/conversations/').doc('${FirebaseAuth.instance.currentUser.uid}').set({
    'unread': true,
  });
}

Future<void> toggleLike(FeedItemModel feedItem, bool currentUserLikes) async {
  var docSnapshot = await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.getId).get();
  var userLikes = await docSnapshot.reference.collection('likes_users').doc(FirebaseAuth.instance.currentUser.uid).get();

  // int oldLikes = docSnapshot.data()['likes'];
  if (userLikes.exists && currentUserLikes) {
    // await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.getId).update({'likes': oldLikes - 1});
    // feedItem.likes -= 1;
    await FirebaseFirestore.instance
        .collection('feed_item')
        .doc(feedItem.getId)
        .collection('likes_users')
        .doc(FirebaseAuth.instance.currentUser.uid)
        .delete();
  } else if (!userLikes.exists && !currentUserLikes) {
    // await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.getId).update({'likes': oldLikes + 1});
    // feedItem.likes += 1;
    await FirebaseFirestore.instance
        .collection('feed_item')
        .doc(feedItem.getId)
        .collection('likes_users')
        .doc(FirebaseAuth.instance.currentUser.uid)
        .set({});
  }
}

Future<void> showMyDialog(FeedItemModel feedItem, context, String type) async {
  if (type == 'help') {
    Navigator.pushNamed(context, '/help_close', arguments: feedItem);
    return null;
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      if (type == 'activity') {
        return AlertDialog(
          title: Text('Deseja mesmo excluir a atividade?'),
          actions: <Widget>[
            TextButton(
              child: Text('Excluir'),
              onPressed: () async {
                await deleteActivity(feedItem, feedItem.getUserId);
                Navigator.pushNamedAndRemoveUntil(context, '/main_feed', (route) => false);
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      } else if (type == 'alert') {
        return AlertDialog(
          title: Text('Deseja mesmo excluir o alerta?'),
          actions: <Widget>[
            TextButton(
              child: Text('Excluir'),
              onPressed: () async {
                await deleteAlert(feedItem, feedItem.getUserId);
                Navigator.pushReplacementNamed(context, '/main_feed');
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
      return null;
    },
  );
}

Future<void> updateSettings(showOnlyFriendsFeed, showActivityFeed, showAlertsFeed, showHelpFeed) async {
  await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).update({
    'show_activity_feed': showActivityFeed,
    'show_alerts_feed': showAlertsFeed,
    'show_help_feed': showHelpFeed,
    'show_only_friends_feed': showOnlyFriendsFeed,
  });
}

Future<bool> showMyDialogFeedSettings(context, showOnlyFriendsFeed, showActivityFeed, showAlertsFeed, showHelpFeed) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Opções'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: Text(
                        "Filtrar publicações",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Radio(
                        value: false,
                        groupValue: showOnlyFriendsFeed,
                        onChanged: (value) {
                          setState(() => showOnlyFriendsFeed = value);
                        },
                      ),
                      Flexible(
                        child: Text(
                          "Mostrar todos os usuários no feed",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Radio(
                        value: true,
                        groupValue: showOnlyFriendsFeed,
                        onChanged: (value) {
                          setState(() => showOnlyFriendsFeed = value);
                        },
                      ),
                      Flexible(
                        child: Text(
                          "Mostrar apenas quem eu sigo no feed",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: Text(
                        "Tipos de publicações",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: showAlertsFeed,
                        onChanged: (value) {
                          setState(() => showAlertsFeed = value);
                        },
                      ),
                      Flexible(
                        child: Text(
                          "Mostrar alertas",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: showHelpFeed,
                        onChanged: (value) {
                          setState(() => showHelpFeed = value);
                        },
                      ),
                      Flexible(
                        child: Text(
                          "Mostrar pedidos de ajuda",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: showActivityFeed,
                        onChanged: (value) {
                          setState(() => showActivityFeed = value);
                        },
                      ),
                      Flexible(
                        child: Text(
                          "Mostrar atividades",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Salvar'),
            onPressed: () async {
              updateSettings(showOnlyFriendsFeed, showActivityFeed, showAlertsFeed, showHelpFeed);
              Navigator.of(context).pop(true);
            },
          ),
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ],
      );
    },
  );
  return result;
}

Future<void> deleteAlert(FeedItemModel feedItem, String userId) async {
  var feedItemLikes = await FirebaseFirestore.instance.collection('feed_item/${feedItem.getId}/likes_users').get();
  for (var doc in feedItemLikes.docs) {
    await doc.reference.delete();
  }
  await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.getId).delete();
  await FirebaseFirestore.instance.collection('alerts').doc(feedItem.getParentId).delete();

  QuerySnapshot followersSnapshot = await FirebaseFirestore.instance.collection('users/$userId/followers_users').get();
  List<String> followersIds = followersSnapshot.docs.map((e) => e.id).toList();
  followersIds.forEach((userId) {
    FirebaseFirestore.instance
        .collection('users/$userId/feed_item')
        .where('alert_id', isEqualTo: feedItem.getParentId)
        .get()
        .then((querySnapshot) async {
      // Once we get the results, begin a batch
      var batch = FirebaseFirestore.instance.batch();

      querySnapshot.docs.forEach((doc) {
        // For each doc, add a delete operation to the batch
        batch.delete(doc.reference);
      });

      // Commit the batch
      await batch.commit();
    });
  });
}

Future<void> deleteActivity(FeedItemModel feedItem, String userId) async {
  var feedItemLikes = await FirebaseFirestore.instance.collection('feed_item/${feedItem.getId}/likes_users').get();
  for (var doc in feedItemLikes.docs) {
    await doc.reference.delete();
  }
  await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.getId).delete();
  await FirebaseFirestore.instance.collection('activities').doc(feedItem.getParentId).delete();

  QuerySnapshot followersSnapshot = await FirebaseFirestore.instance.collection('users/$userId/followers_users').get();
  List<String> followersIds = followersSnapshot.docs.map((e) => e.id).toList();
  followersIds.forEach((userId) {
    FirebaseFirestore.instance
        .collection('users/$userId/feed_item')
        .where('activity_id', isEqualTo: feedItem.getParentId)
        .get()
        .then((querySnapshot) async {
      // Once we get the results, begin a batch
      var batch = FirebaseFirestore.instance.batch();

      querySnapshot.docs.forEach((doc) {
        // For each doc, add a delete operation to the batch
        batch.delete(doc.reference);
      });

      // Commit the batch
      await batch.commit();
    });
  });
}

Future<void> closeHelpRequest(FeedItemModel feedItem, String providerUserId, BuildContext context) async {
  var helpRequest = await FirebaseFirestore.instance.collection('help_request').doc(feedItem.getParentId).get();

  if (providerUserId != null) {
    await helpRequest.reference.update({
      'active': false,
      'provider_user_id': providerUserId,
      'date_time_closed': DateTime.now(),
    });

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(providerUserId).get();
    var previousExperience = userDoc.data()['experience'];
    await FirebaseFirestore.instance.collection('users').doc(providerUserId).update({'experience': previousExperience + 500});
  } else {
    await helpRequest.reference.update({
      'active': false,
    });
  }

  QuerySnapshot followersSnapshot =
      await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/followers_users').get();
  List<String> followersIds = followersSnapshot.docs.map((e) => e.id).toList();
  followersIds.forEach((userId) {
    FirebaseFirestore.instance
        .collection('users/$userId/feed_item')
        .where('help_request_id', isEqualTo: feedItem.getParentId)
        .get()
        .then((querySnapshot) async {
      // Once we get the results, begin a batch
      var batch = FirebaseFirestore.instance.batch();

      querySnapshot.docs.forEach((doc) {
        // For each doc, add a delete operation to the batch
        batch.update(doc.reference, {'active': false});
      });

      // Commit the batch
      await batch.commit();
    });
  });

  String feedItemId = helpRequest.data()['feed_item_id'];
  var feedItemSnapshot = await FirebaseFirestore.instance.collection('feed_item').doc(feedItemId).get();
  await feedItemSnapshot.reference.update({'active': false});

  AchievementHandler.updateStat(providerUserId, Statistic.users_helped, 1, context);
}
