import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';
import 'package:intl/intl.dart';

class HelpCardDetails extends StatefulWidget {
  @override
  _HelpCardDetailsState createState() => _HelpCardDetailsState();
}

class _HelpCardDetailsState extends State<HelpCardDetails> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    List<dynamic> args = ModalRoute.of(context).settings.arguments;
    FeedItemModel feedItem = args[0];
    Set<Marker> markers = args[1];

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes do pedido"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  FirebaseAuth.instance.currentUser.uid == feedItem.getUserId
                      ? InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/help_close', arguments: feedItem);
                          },
                          child: Card(
                            elevation: 3,
                            margin: EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 20),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'lib/assets/images/help_icon.png',
                                    scale: 2,
                                  ),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      "Este pedido está ativo, aperte aqui caso queira encerrá-lo.",
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(),
                  Card(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/profile', arguments: feedItem.getUserId);
                            },
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(feedItem.avatarUrl),
                              radius: 28,
                            ),
                          ),
                          title: Text(
                            feedItem.getTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 19,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMMd().format(feedItem.getDateTime) + " às " + DateFormat.jm().format(feedItem.getDateTime),
                          ),
                          trailing: FirebaseAuth.instance.currentUser.uid == feedItem.getUserId
                              ? PopupMenuButton(
                                  child: IconButton(
                                    iconSize: 32,
                                    icon: Icon(Icons.more_vert),
                                  ),
                                  itemBuilder: (context) {
                                    return [
                                      PopupMenuItem(
                                        child: InkWell(
                                          child: Text('Encerrar pedido'),
                                          onTap: () {
                                            showMyDialog(feedItem, context, 'help');
                                          },
                                        ),
                                      )
                                    ];
                                  },
                                )
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 15, left: 15, top: 10),
                            child: Text(
                              feedItem.getDescription,
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 20, left: 10, right: 10),
                          height: MediaQuery.of(context).size.height * 0.40,
                          child: Image.network(feedItem.getImageUrl),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.50,
                          child: GoogleMap(
                            markers: markers,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(feedItem.getLatitude, feedItem.getLongitude),
                              zoom: 15.0,
                            ),
                          ),
                        ),
                        TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Veja este pedido de ajuda no mapa ",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(width: 3),
                              Container(
                                width: 25,
                                child: Image.asset(
                                  'lib/assets/images/map_icon.png',
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/show_map_screen', arguments: [feedItem.getLatitude, feedItem.getLongitude]);
                          },
                        ),
                        FirebaseAuth.instance.currentUser.uid != feedItem.getUserId
                            ? TextButton(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "Mandar uma mensagem para " + feedItem.getProfileName + " ",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Icon(
                                      Icons.mail_outline,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/chat',
                                      arguments: [feedItem.getUserId, feedItem.getProfileName, feedItem.avatarUrl]);
                                },
                              )
                            : SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
    ;
  }
}
