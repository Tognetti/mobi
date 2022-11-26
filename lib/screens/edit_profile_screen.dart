import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobi/widgets/user_image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File _userImageFile;
  final _formKey = GlobalKey<FormState>();
  String _userName = '';
  String _cidade = '';
  String _estado = '';
  var isLoading = false;

  void _pickedImage(File image) {
    _userImageFile = image;
  }

  Future<DocumentSnapshot> fetchUserData() async {
    DocumentSnapshot userDocumentSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).get();
    return userDocumentSnapshot;
  }

  Future<void> updateUserData(String username, String cidade, String estado, File image, String currentImageUrl, BuildContext ctx) async {
    try {
      setState(() {
        isLoading = true;
      });

      var url = currentImageUrl;
      if (image != null) {
        final ref = FirebaseStorage.instance.ref().child('user_image').child(FirebaseAuth.instance.currentUser.uid + '.jpg');
        await ref.putFile(image);
        url = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).update({
        'username': username,
        'image_url': url,
        'cidade': cidade,
        'estado': estado,
      });
    } catch (e) {
      Scaffold.of(ctx).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void showSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          child: Text("Alterações salvas!"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Editar perfil")),
      body: FutureBuilder(
          future: fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.connectionState == ConnectionState.done) {
              var userData = snapshot.data.data();
              return Container(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Card(
                        elevation: 7,
                        margin: EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: <Widget>[
                                  UserImagePicker(_pickedImage, userData['image_url']),
                                  TextFormField(
                                    initialValue: userData['username'],
                                    key: ValueKey('nome'),
                                    decoration: InputDecoration(labelText: 'Nome'),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'Insira um nome';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _userName = value;
                                    },
                                  ),
                                  TextFormField(
                                    initialValue: userData['cidade'],
                                    key: ValueKey('cidade'),
                                    decoration: InputDecoration(labelText: 'Cidade'),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'Insira sua cidade';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _cidade = value;
                                    },
                                  ),
                                  TextFormField(
                                    initialValue: userData['estado'],
                                    key: ValueKey('estado'),
                                    decoration: InputDecoration(labelText: 'Estado'),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'Insira seu estado';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _estado = value;
                                    },
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  if (!isLoading)
                                    ElevatedButton(
                                      child: Text(
                                        "Salvar",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () async {
                                        final isValid = _formKey.currentState.validate();
                                        FocusScope.of(context).unfocus();

                                        if (isValid) {
                                          _formKey.currentState.save();
                                          print("LOG user");
                                          print(_userName);
                                          await updateUserData(_userName, _cidade, _estado, _userImageFile, userData['image_url'], context);
                                          showSnackbar();
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              );
            }
            return Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
