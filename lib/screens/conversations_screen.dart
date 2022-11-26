import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversations extends StatefulWidget {
  @override
  _ConversationsState createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  List conversations = [];

  markAsRead(conversationId) {
    FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations').doc(conversationId).update({
      'unread': false,
    });
  }

  Future<void> fetchConversations() async {
    conversations = [];
    final conversationsCollection =
        await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations').get();

    for (var element in conversationsCollection.docs) {
      if (element.id != 'dummy_conversation') {
        FontWeight weight;
        if (element.data()['unread'] == true) {
          weight = FontWeight.w500;
        } else {
          weight = FontWeight.w400;
        }

        var lastMessage = await FirebaseFirestore.instance
            .collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations/${element.id}/messages')
            .orderBy('createdAt', descending: true)
            .get();
        var userData = await FirebaseFirestore.instance.collection('users/').doc('${element.id}').get();

        conversations.add(ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(userData['image_url']),
            radius: 25,
          ),
          title: Row(
            children: [
              Text(
                userData.data()['username'],
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              element.data()['unread'] == true
                  ? Container(
                      margin: EdgeInsets.only(left: 5),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                      alignment: Alignment.center,
                      child: Text(''),
                    )
                  : Container(),
            ],
          ),
          subtitle: Text(
            lastMessage.docs.first['content'],
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: weight,
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/chat', arguments: [element.id, userData.data()['username'], userData['image_url']])
                .then((_) => markAsRead(element.id));
            // markAsRead(element.id);
          },
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mensagens")),
      body: Container(
        child: StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations').snapshots().asyncMap(
            (event) async {
              await fetchConversations();
              return event;
            },
          ),
          builder: (context, streamSnapshot) {
            if (streamSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (BuildContext context, int i) {
                return conversations[i];
              },
            );
          },
        ),
      ),
    );
  }
}
