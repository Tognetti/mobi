import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FollowingScreen extends StatefulWidget {
  @override
  _FollowingScreenState createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  Future fetchUsers(String userId) async {
    List usersList = [];
    QuerySnapshot currentUserFollowingCollection = await FirebaseFirestore.instance.collection('users/$userId/following_users').get();

    for (var userId in currentUserFollowingCollection.docs) {
      if (userId.id != 'dummy_user') {
        var userDocs = await FirebaseFirestore.instance.collection('users').doc(userId.id).get();
        usersList.add(
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile', arguments: userId.id);
            },
            child: ListTile(
              contentPadding: EdgeInsets.only(bottom: 5, left: 10, right: 10),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userDocs.data()['image_url']),
                radius: 25,
              ),
              title: Text(
                userDocs.data()['username'],
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }
    }

    return usersList;
  }

  @override
  Widget build(BuildContext context) {
    String userId = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text("Seguindo"),
      ),
      body: FutureBuilder(
        future: fetchUsers(userId),
        builder: (context, snapshot) {
          List userList = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              padding: EdgeInsets.only(top: 10),
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return userList[index];
                },
                itemCount: userList.length,
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
