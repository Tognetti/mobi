import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobi/backoffice/achievement_handler.dart';
import 'package:mobi/exceptions/exceptions.dart';

class AlertDetailsScreen extends StatefulWidget {
  @override
  _AlertDetailsScreenState createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _userName;
  File _pickedImage;
  bool _isLoading = false;

  void saveAlert(latLong) async {
    final isValid = _formKey.currentState.validate();
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_pickedImage == null) {
        throw NullImage('É necessário inserir uma imagem');
      }

      _formKey.currentState.save();
      String currentUserId = FirebaseAuth.instance.currentUser.uid;
      final userData = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      _userName = userData.data()['username'];

      var alert = await FirebaseFirestore.instance.collection('alerts').add({
        'latitude': latLong[0],
        'longitude': latLong[1],
        'user_id': currentUserId,
        'user_name': _userName,
        'title': _title,
        'description': _description,
        'image_url': '',
        'date_time': DateTime.now(),
      });

      final ref = FirebaseStorage.instance.ref().child('alert_image').child(alert.id + '.jpg');
      await ref.putFile(_pickedImage);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('alerts').doc(alert.id).update(
        {'image_url': url},
      );

      // Cria um feed_item "geral"
      DocumentReference feedItem = await FirebaseFirestore.instance.collection('feed_item').add({
        'type': 'alert',
        'alert_id': alert.id,
        'date_time': DateTime.now().toIso8601String(),
        'user_id': currentUserId,
        'number_comments': 0,
        'active': true,
      });

      // Cria um feed_item para todos os seguidores de quem criou o alerta
      QuerySnapshot followersSnapshot =
          await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser.uid}/followers_users').get();
      List<String> followersIds = followersSnapshot.docs.map((e) => e.id).toList();

      followersIds.forEach((userId) async {
        await FirebaseFirestore.instance.collection('users/$userId/feed_item').add({
          'type': 'alert',
          'alert_id': alert.id,
          'general_feed_item_id': feedItem.id,
          'date_time': DateTime.now().toIso8601String(),
          'user_id': currentUserId,
          'number_comments': 0,
          'active': true,
        });
      });

      await FirebaseFirestore.instance
          .collection('feed_item')
          .doc(feedItem.id)
          .collection('likes_users')
          .doc("dummy_user")
          .set({'user_id': null});

      var previousExperience = userData.data()['experience'];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser.uid)
          .update({'experience': previousExperience + 100});

      await FirebaseFirestore.instance.collection('alerts').doc(alert.id).update(
        {'feed_item_id': feedItem.id},
      );

      AchievementHandler.updateStat(currentUserId, Statistic.alert_count, 1, context);
      Navigator.pushNamed(context, '/alert_create_confirmation');
    } on NullImage catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _pickImage() async {
    final picker = ImagePicker();
    var pickedImage;
    var pickedImageFile;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.photo_library),
                    title: new Text('Galeria'),
                    onTap: () async {
                      pickedImage = await picker.getImage(
                        source: ImageSource.gallery,
                      );
                      pickedImageFile = File(pickedImage.path);
                      setState(() {
                        _pickedImage = pickedImageFile;
                      });
                      Navigator.of(context).pop();
                    }),
                new ListTile(
                  leading: new Icon(Icons.photo_camera),
                  title: new Text('Câmera'),
                  onTap: () async {
                    pickedImage = await picker.getImage(
                      source: ImageSource.camera,
                    );
                    pickedImageFile = File(pickedImage.path);
                    setState(() {
                      _pickedImage = pickedImageFile;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var latLong = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes do alerta"),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Título'),
                  onSaved: (value) {
                    _title = value;
                  },
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Insira um título';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  maxLines: 5,
                  decoration: InputDecoration(labelText: 'Descrição'),
                  onSaved: (value) {
                    _description = value;
                  },
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Insira uma descrição';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    color: _pickedImage == null ? Colors.grey.shade300 : null,
                    alignment: Alignment.center,
                    child: _pickedImage == null
                        ? Icon(
                            Icons.add_a_photo_outlined,
                            size: 60,
                          )
                        : Image.file(_pickedImage),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                _isLoading
                    ? CircularProgressIndicator()
                    : RaisedButton(
                        color: Colors.green,
                        child: Text(
                          "Criar alerta",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () {
                          saveAlert(latLong);
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
