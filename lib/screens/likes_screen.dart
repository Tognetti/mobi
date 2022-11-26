import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LikesScreen extends StatefulWidget {
  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  var usersListTile = [];

  Future getUsers(String id) async {
    usersListTile = [];
    var resultados = await FirebaseFirestore.instance.collection('feed_item/$id/likes_users').get();

    for (var userId in resultados.docs) {
      if (userId.id != 'dummy_user') {
        var userDocs = await FirebaseFirestore.instance.collection('users').doc(userId.id).get();
        usersListTile.add(
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

    return usersListTile;
  }

  @override
  Widget build(BuildContext context) {
    String itemId = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Curtidas'),
      ),
      body: FutureBuilder(
        future: getUsers(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Container(
              padding: EdgeInsets.only(top: 10),
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return snapshot.data[index];
                },
                itemCount: snapshot.data.length,
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
