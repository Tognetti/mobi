import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  String messageContent;
  String messageType;

  ChatMessage({@required this.messageContent, @required this.messageType});
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    List<dynamic> args = ModalRoute.of(context).settings.arguments;
    String userId = args[0];
    String userName = args[1];
    String imageUrl = args[2];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16, left: 50),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: NetworkImage(imageUrl),
                  maxRadius: 20,
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        userName,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users/${FirebaseAuth.instance.currentUser.uid}/conversations/$userId/messages')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, chatSnapshot) {
              if (chatSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              final chatDocs = chatSnapshot.data.docs;
              return ListView.builder(
                reverse: true,
                itemCount: chatDocs.length,
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 10, bottom: 60),
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
                    child: Align(
                      alignment: (chatDocs[index]['type'] == "received" ? Alignment.topLeft : Alignment.topRight),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (chatDocs[index]['type'] == "received" ? Colors.grey.shade200 : Colors.green[200]),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Text(
                          chatDocs[index]['content'],
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: TextField(
                      controller: myController,
                      decoration: InputDecoration(
                          hintText: "Escreva sua mensagem...", hintStyle: TextStyle(color: Colors.black54), border: InputBorder.none),
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      sendMessage(userId, myController.text);
                      myController.clear();
                    },
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    backgroundColor: Colors.green,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    ;
  }
}
