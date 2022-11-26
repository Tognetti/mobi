import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobi/screens/edit_profile_screen.dart';
import 'package:mobi/backoffice/achievement_handler.dart';

// ignore: must_be_immutable
class ProfileAppBar extends StatefulWidget implements PreferredSizeWidget {
  ProfileAppBar(this.isFollowing, this.userId, this.refreshParent);

  bool isFollowing;
  final String userId;
  final Function() refreshParent;

  Size get preferredSize => new Size.fromHeight(kToolbarHeight);

  @override
  _ProfileAppBarState createState() => _ProfileAppBarState();
}

class _ProfileAppBarState extends State<ProfileAppBar> {
  Future<void> followUnfollow(userId, ctx) async {
    if (widget.isFollowing) {
      await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/following_users').doc(userId).delete();
      await FirebaseFirestore.instance.collection('users/$userId/followers_users').doc(FirebaseAuth.instance.currentUser.uid).delete();

      // Remove feed_item do user que não está mais sendo seguido do feed do user que deixou de seguir
      QuerySnapshot feedItemSnapshot = await FirebaseFirestore.instance
          .collection('users/${FirebaseAuth.instance.currentUser.uid}/feed_item')
          .where('user_id', isEqualTo: userId)
          .get();
      var batch = FirebaseFirestore.instance.batch();
      feedItemSnapshot.docs.forEach((doc) {
        batch.delete(doc.reference);
      });
      await batch.commit();

      AchievementHandler.updateStat(FirebaseAuth.instance.currentUser.uid, Statistic.users_followed, -1, ctx);
    } else {
      await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/following_users').doc(userId).set({});
      await FirebaseFirestore.instance.collection('users/$userId/followers_users').doc(FirebaseAuth.instance.currentUser.uid).set({});

      // Adiciona feed_item do user que foi seguido no feed do user que seguiu
      QuerySnapshot feedItemSnapshot = await FirebaseFirestore.instance.collection('feed_item').where('user_id', isEqualTo: userId).get();
      feedItemSnapshot.docs.forEach((feedItem) async {
        print("LOG");
        print(feedItem.data()['type']);
        switch (feedItem.data()['type']) {
          case 'activity':
            var newActivity = await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/feed_item').add({
              'type': feedItem.data()['type'],
              'activity_id': feedItem.data()['activity_id'],
              'general_feed_item_id': feedItem.id,
              'date_time': feedItem.data()['date_time'],
              'user_id': feedItem.data()['user_id'],
              'number_comments': feedItem.data()['number_comments'],
              'active': feedItem.data()['active'],
            });
            await FirebaseFirestore.instance
                .collection('users/${FirebaseAuth.instance.currentUser.uid}/feed_item')
                .doc(newActivity.id)
                .collection('likes_users')
                .doc("dummy_user")
                .set({'user_id': null});
            break;
          case 'alert':
            var newAlert = await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/feed_item').add({
              'type': feedItem.data()['type'],
              'alert_id': feedItem.data()['alert_id'],
              'general_feed_item_id': feedItem.id,
              'date_time': feedItem.data()['date_time'],
              'user_id': feedItem.data()['user_id'],
              'number_comments': feedItem.data()['number_comments'],
              'active': feedItem.data()['active'],
            });
            await FirebaseFirestore.instance
                .collection('users/${FirebaseAuth.instance.currentUser.uid}/feed_item')
                .doc(newAlert.id)
                .collection('likes_users')
                .doc("dummy_user")
                .set({'user_id': null});
            break;
          case 'help':
            await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/feed_item').add({
              'type': feedItem.data()['type'],
              'help_request_id': feedItem.data()['help_request_id'],
              'general_feed_item_id': feedItem.id,
              'date_time': feedItem.data()['date_time'],
              'user_id': feedItem.data()['user_id'],
              'active': feedItem.data()['active'],
            });
            break;
        }
      });

      AchievementHandler.updateStat(FirebaseAuth.instance.currentUser.uid, Statistic.users_followed, 1, ctx);
    }

    widget.isFollowing = !widget.isFollowing;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text("Perfil"),
      actions: FirebaseAuth.instance.currentUser.uid == widget.userId
          ? [
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen())).whenComplete(widget.refreshParent);
                },
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.create,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        "Editar",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : [
              InkWell(
                onTap: () {
                  followUnfollow(widget.userId, context);
                },
                child: Row(
                  children: [
                    IconButton(
                      icon: widget.isFollowing
                          ? Icon(
                              Icons.person_remove_sharp,
                              color: Colors.white,
                            )
                          : Icon(
                              Icons.person_add,
                              color: Colors.white,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: widget.isFollowing
                          ? Text(
                              "Deixar de seguir",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          : Text(
                              "Seguir",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],
    );
  }
}
