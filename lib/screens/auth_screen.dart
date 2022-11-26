import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobi/backoffice/achievement_handler.dart';
import 'package:mobi/exceptions/exceptions.dart';
import 'package:mobi/widgets/auth_form.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  var _isLoading = false;

  void _submitAuthForm(
      String email, String password, String username, String cidade, String estado, bool isLogin, File image, BuildContext ctx) async {
    UserCredential userCredential;

    //Default avatar image url
    var url =
        'https://firebasestorage.googleapis.com/v0/b/mobiaplicativo.appspot.com/o/user_image%2Favatar.png?alt=media&token=a2e259c0-737b-400f-9d3f-897814951754';

    try {
      setState(() {
        _isLoading = true;
      });
      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        if (image == null) {
          throw NullImage('É necessário inserir uma imagem');
        }
        userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

        if (image != null) {
          final ref = FirebaseStorage.instance.ref().child('user_image').child(userCredential.user.uid + '.jpg');
          await ref.putFile(image);
          url = await ref.getDownloadURL();
        }

        // final allAchievementsCollection = await FirebaseFirestore.instance.collection('achievements').orderBy('name').get();

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user.uid).set({
          'username': username,
          'email': email,
          'image_url': url,
          'cidade': cidade,
          'estado': estado,
          // 'completed_help_requests': 0,
          'show_only_friends_feed': false,
          'show_alerts_feed': true,
          'show_help_feed': true,
          'show_activity_feed': true,
          'experience': 0,
        });

        final emptyStat = {'value': 0};
        for (var stat in Statistic.values) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user.uid)
              .collection('statistics')
              .doc(describeEnum(stat))
              .set(emptyStat);
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user.uid)
            .collection('user_achievements')
            .doc("dummy_achievement")
            .set({
          'achievement_id': null,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user.uid)
            .collection('conversations')
            .doc("dummy_conversation")
            .set({
          'user_id': null,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user.uid)
            .collection('following_users')
            .doc("dummy_user")
            .set({
          'user_id': null,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user.uid)
            .collection('followers_users')
            .doc("dummy_user")
            .set({
          'user_id': null,
        });
      }
    } on FirebaseAuthException catch (e) {
      //Mensagem genérica
      var message = "Um erro ocorreu, verifique suas credenciais";

      if (e.message != null) {
        if (e.code == "ERROR_WEAK_PASSWORD" || e.code == "weak-password") {
          message = "Sua senha deve ter no mínimo 6 caracteres";
        } else if (e.code == "ERROR_INVALID_EMAIL" || e.code == "invalid-email") {
          message = "Insira um e-mail válido";
        } else {
          message = message + e.message;
        }
      }

      Scaffold.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } on NullImage catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } catch (e) {
      Scaffold.of(ctx).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffe9f5e1),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'lib/assets/images/mobi_logo.png',
                scale: 14,
              ),
              SizedBox(
                height: 10,
              ),
              AuthForm(_submitAuthForm, _isLoading),
              Card(
                elevation: 7,
                margin: EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Olá! Obrigado por participar das avaliações do nosso projeto.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17),
                      ),
                      SizedBox(height: 15),
                      InkWell(
                        child: Text(
                          "Aperte aqui para acessar o questionário",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17,color: Colors.blue),
                        ),
                        onTap: () {
                          launch('https://www.google.com');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
