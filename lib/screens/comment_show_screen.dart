import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobi/models/feed_item_model.dart';

class ShowCommentsScreen extends StatefulWidget {
  @override
  _ShowCommentsScreenState createState() => _ShowCommentsScreenState();
}

class _ShowCommentsScreenState extends State<ShowCommentsScreen> {
  List commentsList = [];

  Future<void> loadComments(feedItemId) async {
    commentsList = [];
    var commentsCollection = await FirebaseFirestore.instance.collection('feed_item/$feedItemId/comments/').orderBy('createdAt').get();
    var commentsDocs = commentsCollection.docs;

    for (var comment in commentsDocs) {
      var userDoc = await FirebaseFirestore.instance.collection('users/').doc(comment.data()['user_id']).get();

      commentsList.add({
        'content': comment.data()['content'],
        'dateTime': comment.data()['createdAt'],
        'user_id': comment.data()['user_id'],
        'username': userDoc.data()['username'],
        'user_image': userDoc.data()['image_url'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    FeedItemModel feedItem = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Comentários'),
      ),
      body: FutureBuilder(
          future: loadComments(feedItem.getId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Container(
                height: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 15),
                  itemBuilder: (context, index) {
                    if (index == commentsList.length) {
                      return ElevatedButton(
                          onPressed: () {
                            // Navigator.pushReplacementNamed(context, '/add_comment', arguments: feedItem);
                            Navigator.pushNamed(context, '/add_comment', arguments: feedItem).then((value) => setState(() {}));
                          },
                          child: Text('Escrever um comentário'));
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Container(
                        child: Column(
                          children: [
                            Container(
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      child: CircleAvatar(
                                        radius: 25,
                                        backgroundImage: NetworkImage(
                                          commentsList[index]['user_image'],
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(context, '/profile', arguments: commentsList[index]['user_id']);
                                      },
                                    ),
                                    SizedBox(width: 10),
                                    Container(
                                      child: Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            InkWell(
                                              child: Text(
                                                commentsList[index]['username'],
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              onTap: () {
                                                Navigator.pushNamed(context, '/profile', arguments: commentsList[index]['user_id']);
                                              },
                                            ),
                                            Text(
                                              DateFormat.yMMMMd().format(commentsList[index]['dateTime'].toDate()) +
                                                  " às " +
                                                  DateFormat.jm().format(commentsList[index]['dateTime'].toDate()),
                                              style: TextStyle(fontSize: 12, color: Colors.black54),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              commentsList[index]['content'],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Divider(),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: commentsList.length + 1,
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }
}
