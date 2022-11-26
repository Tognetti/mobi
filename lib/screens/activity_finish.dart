import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mobi/backoffice/achievement_handler.dart';
import 'package:mobi/exceptions/exceptions.dart';
import 'package:mobi/widgets/activity_info.dart';

class ActivityFinishScreen extends StatefulWidget {
  @override
  _ActivityFinishScreenState createState() => _ActivityFinishScreenState();
}

class _ActivityFinishScreenState extends State<ActivityFinishScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  File _pickedImage;
  bool _isLoading = false;
  String _userName;

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

  void saveActivity(List<LatLng> coordinates, double distance, Duration time) async {
    final isValid = _formKey.currentState.validate();
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _formKey.currentState.save();
      String currentUserId = FirebaseAuth.instance.currentUser.uid;
      final userData = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      _userName = userData.data()['username'];

      // if (_pickedImage == null) {
      //   throw NullImage('É necessário inserir uma imagem');
      // }

      List formattedCoordinates = coordinates.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList();

      var activity = await FirebaseFirestore.instance.collection('activities').add({
        'user_id': currentUserId,
        'user_name': _userName,
        'title': _title,
        'description': _description,
        'image_url': '',
        'coordinates': formattedCoordinates,
        'distance_meters': distance,
        'duration_seconds': time.inSeconds,
        'date_time': DateTime.now(),
      });

      AchievementHandler.updateStat(currentUserId, Statistic.activity_time, time.inSeconds, context);
      AchievementHandler.updateStat(currentUserId, Statistic.distance_ridden, distance, context);
      AchievementHandler.updateStat(currentUserId, Statistic.activity_count, 1, context);

      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('activity_image').child(activity.id + '.jpg');
        await ref.putFile(_pickedImage);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('activities').doc(activity.id).update(
          {'image_url': url},
        );
      }

      // Cria um feed_item "geral"
      DocumentReference feedItem = await FirebaseFirestore.instance.collection('feed_item').add({
        'type': 'activity',
        'activity_id': activity.id,
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
          'type': 'activity',
          'activity_id': activity.id,
          'general_feed_item_id': feedItem.id,
          'date_time': DateTime.now().toIso8601String(),
          'user_id': currentUserId,
          'number_comments': 0,
          'active': true,
        });
      });

      await FirebaseFirestore.instance.collection('feed_item').doc(feedItem.id).collection('likes_users').doc("dummy_user").set({
        'user_id': null,
      });

      await FirebaseFirestore.instance.collection('activities').doc(activity.id).update(
        {'feed_item_id': feedItem.id},
      );

      Navigator.pushNamed(context, '/activity_create_confirmation');
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

  @override
  Widget build(BuildContext context) {
    Arguments args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text("Concluir atividade"),
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
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Insira um título';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _title = value;
                  },
                ),
                TextFormField(
                  maxLines: 5,
                  decoration: InputDecoration(labelText: 'Descrição'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Insira uma descrição';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _description = value;
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
                    : SizedBox(
                        width: 180,
                        child: RaisedButton(
                          child: Text(
                            "Salvar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () {
                            saveActivity(args.coordinates, args.distance, args.time);
                          },
                          color: Colors.green,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
