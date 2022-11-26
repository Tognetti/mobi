import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobi/screens/activity_screen.dart';
import 'package:mobi/screens/alert_screen.dart';
import 'package:mobi/screens/help_create_map_screen.dart';

class NavDrawer extends Container {
  final Function() notifyParent;

  NavDrawer(this.notifyParent);

  @override
  Widget build(BuildContext context) => Container(
        child: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            // This makes it so the drawer continues on the background of android top bar (where the clock and battery are)
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                height: 170,
                child: DrawerHeader(
                  padding: EdgeInsets.all(0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(Colors.white.value).withOpacity(0.80),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: (FirebaseAuth.instance.currentUser != null)
                              ? StreamBuilder(
                                  stream:
                                      FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    if (snapshot.hasData && snapshot.data.data() != null) {
                                      return CircleAvatar(
                                        radius: 45,
                                        backgroundImage: NetworkImage(snapshot.data.data()['image_url']),
                                      );
                                    }
                                    return CircularProgressIndicator();
                                  },
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("lib/assets/images/background.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              (FirebaseAuth.instance.currentUser != null)
                  ? StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 50,
                          );
                        }
                        if (snapshot.hasData && snapshot.data.data() != null) {
                          return ListTile(
                            title: Text(
                              "Olá " + snapshot.data.data()['username'] + "!",
                              style: TextStyle(fontSize: 20),
                            ),
                          );
                        }
                        return Container(
                          height: 50,
                        );
                      },
                    )
                  : null,
              ListTile(
                dense: true,
                title: Text('Meu perfil'),
                onTap: () {
                  Navigator.pushNamed(context, '/profile', arguments: FirebaseAuth.instance.currentUser.uid)
                      .then((value) => notifyParent());
                },
              ),
              ListTile(
                dense: true,
                title: Text('Minhas estatísticas'),
                onTap: () {
                  Navigator.pushNamed(context, '/statistics').then((value) => notifyParent());
                },
              ),
              ListTile(
                dense: true,
                title: Text('Criar alerta'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AlertScreen()));
                },
              ),
              ListTile(
                dense: true,
                title: Text('Criar pedido de ajuda'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HelpMapScreen()));
                },
              ),
              ListTile(
                dense: true,
                title: Text('Registrar atividade'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityScreen()));
                },
              ),
              ListTile(
                dense: true,
                title: Text('Mapa de alertas e pedidos'),
                onTap: () {
                  Navigator.pushNamed(context, '/show_map_screen');
                },
              ),
              ListTile(
                dense: true,
                title: Text('Sair'),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      );
}
