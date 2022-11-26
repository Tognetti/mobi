import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobi/models/feed_item_model.dart';

class AddCommentScreen extends StatefulWidget {
  @override
  _AddCommentScreenState createState() => _AddCommentScreenState();
}

class _AddCommentScreenState extends State<AddCommentScreen> {
  String message = '';
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> sendComment(feedItemId) async {
    await FirebaseFirestore.instance.collection('feed_item/$feedItemId/comments/').add({
      'content': message,
      'createdAt': Timestamp.now(),
      'user_id': FirebaseAuth.instance.currentUser.uid,
    });
    var feedItemDoc = await FirebaseFirestore.instance.collection('feed_item/').doc(feedItemId).get();
    var n = feedItemDoc.data()['number_comments'];
    await FirebaseFirestore.instance.collection('feed_item/').doc(feedItemId).update({
      'number_comments': n + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    FeedItemModel feedItem = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar comentário'),
      ),
      body: Container(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                child: TextFormField(
                  maxLines: 5,
                  decoration: InputDecoration(labelText: 'Comentário'),
                  onSaved: (value) {
                    message = value;
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        formKey.currentState.save();
                        setState(() {
                          isLoading = true;
                        });
                        await sendComment(feedItem.getId);
                        setState(() {
                          isLoading = false;
                        });
                        // Navigator.popAndPushNamed(context, '/show_comments', arguments: feedItem);
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Enviar comentário",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
