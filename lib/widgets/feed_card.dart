import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';
import 'package:intl/intl.dart';
import 'package:mobi/screens/show_map_screen.dart';

class FeedCard extends StatefulWidget {
  FeedCard({Key key, this.item, this.notifyParent}) : super(key: key);
  final FeedItemModel item;
  final Function() notifyParent;

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  final Set<Marker> _markersHelp = {};
  final Set<Marker> _markersAlert = {};
  bool isLoading = false;

  @override
  void initState() {
    if (widget.item.type == 'help' || widget.item.type == 'alert') {
      loadMarkers();
    }
    super.initState();
  }

  loadMarkers() async {
    BitmapDescriptor helpIcon =
        await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 1), 'lib/assets/images/help_icon.png');
    BitmapDescriptor alertIcon =
        await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 1), 'lib/assets/images/alert_icon.png');

    setState(() {
      _markersHelp.add(Marker(
        markerId: MarkerId('1'),
        position: LatLng(widget.item.latitude, widget.item.longitude),
        icon: helpIcon,
      ));
      _markersAlert.add(Marker(
        markerId: MarkerId('1'),
        position: LatLng(widget.item.latitude, widget.item.longitude),
        icon: alertIcon,
      ));
    });
  }

  Set<Polyline> createPolyLine() {
    List<LatLng> listCoordinates = widget.item.getCoordinates.map((e) => LatLng(e['lat'], e['lng'])).toList();
    return {
      Polyline(
        width: 5,
        polylineId: PolylineId('poly'),
        color: Color.fromARGB(255, 40, 122, 198),
        points: listCoordinates,
      )
    };
  }

  Set<Marker> createMarkers(FeedItemModel feedItem) {
    final Set<Marker> markers = {};
    List<LatLng> listCoordinates = feedItem.getCoordinates.map((e) => LatLng(e['lat'], e['lng'])).toList();

    markers.add(Marker(
      markerId: MarkerId('start'),
      position: listCoordinates.first,
    ));

    markers.add(Marker(
      markerId: MarkerId('end'),
      position: listCoordinates.last,
    ));

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    Future<void> refreshCard() async {
      setState(() {
        isLoading = true;
      });
      final feedItemData = await FirebaseFirestore.instance.collection('feed_item').doc(widget.item.getId).get();
      final likesUsersDocs = await feedItemData.reference.collection('likes_users').get();
      final likesUsersDocsList = likesUsersDocs.docs.toList();
      final likesUsersDocsListIds = likesUsersDocsList.map((e) => e.id);
      setState(() {
        widget.item.setLikes = likesUsersDocsList.length - 1;
        widget.item.setCommentsNumber = feedItemData.data()['number_comments'];
        widget.item.setUserLikes = likesUsersDocsList;
        widget.item.setCurrentUserLike = likesUsersDocsListIds.contains(FirebaseAuth.instance.currentUser.uid);
      });
      setState(() {
        isLoading = false;
      });
    }

    //Verifica qual tipo de Card deve ser exibido
    if (widget.item.getType == 'alert') {
      //Card para alertas
      return Center(
        child: Card(
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/alert_card_details', arguments: [widget.item, _markersAlert]).then((value) => setState(() {
                    refreshCard();
                  }));
            },
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(widget.item.avatarUrl),
                          radius: 23,
                        ),
                        title: Text(
                          widget.item.getProfileName + " adicionou um novo alerta",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          DateFormat.yMMMMd().format(widget.item.getDateTime) + " às " + DateFormat.jm().format(widget.item.getDateTime),
                        ),
                        trailing: FirebaseAuth.instance.currentUser.uid == widget.item.getUserId
                            ? PopupMenuButton(
                                child: IconButton(
                                  iconSize: 32,
                                  icon: Icon(Icons.more_vert),
                                ),
                                itemBuilder: (context) {
                                  return [
                                    // PopupMenuItem(
                                    //   child: Text('Editar'),
                                    // ),
                                    PopupMenuItem(
                                      child: InkWell(
                                        child: Text('Excluir'),
                                        onTap: () {
                                          showMyDialog(widget.item, context, 'alert');
                                        },
                                      ),
                                    )
                                  ];
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 15),
                    child: Text(
                      widget.item.getTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                      left: 15,
                    ),
                    child: Text(widget.item.getDescription),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 0, left: 10, right: 10),
                  height: 250,
                  child: Image.network(widget.item.getImageUrl),
                ),
                TextButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Veja este alerta no mapa ",
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
                    Navigator.pushNamed(context, '/show_map_screen', arguments: [widget.item.getLatitude, widget.item.getLongitude]);
                  },
                ),
                isLoading
                    ? Center(
                        child: Container(
                          child: CircularProgressIndicator(),
                          margin: EdgeInsets.only(bottom: 15),
                        ),
                      )
                    : ButtonBar(
                        alignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: [
                              FlatButton(
                                child: widget.item.currentUserLike ? Icon(Icons.thumb_up) : Icon(Icons.thumb_up_outlined),
                                onPressed: () async {
                                  setState(() {
                                    if (widget.item.currentUserLike) {
                                      widget.item.likes -= 1;
                                    } else {
                                      widget.item.likes += 1;
                                    }
                                    widget.item.currentUserLike = !widget.item.currentUserLike;
                                  });

                                  await toggleLike(widget.item, !widget.item.currentUserLike);
                                  // setState(() {});
                                },
                              ),
                              FlatButton(
                                child: Icon(Icons.comment_outlined),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/add_comment', arguments: widget.item).then((value) => setState(() {
                                        refreshCard();
                                      }));
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                child: widget.item.likes == 1
                                    ? Text(widget.item.likes.toString() + " curtida")
                                    : Text(widget.item.likes.toString() + " curtidas"),
                                onTap: () {
                                  Navigator.pushNamed(context, '/likes', arguments: widget.item.getId);
                                },
                              ),
                              SizedBox(width: 20),
                              InkWell(
                                onTap: () {
                                  // Navigator.pushNamed(context, '/show_comments', arguments: widget.item).then((value) => widget.notifyParent());
                                  Navigator.pushNamed(context, '/show_comments', arguments: widget.item).then((value) => setState(() {
                                        refreshCard();
                                      }));
                                },
                                child: Text("${widget.item.getCommentsNumber} comentários"),
                              ),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      );
    } else if (widget.item.getType == 'activity') {
      //Card para atividades
      return Center(
        child: Card(
          child: Column(
            children: <Widget>[
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/activity_card_details', arguments: widget.item).then((value) => setState(() {
                        refreshCard();
                      }));
                },
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(widget.item.avatarUrl),
                        radius: 23,
                      ),
                      title: Text(
                        widget.item.profileName + " adicionou uma atividade",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        DateFormat.yMMMMd().format(widget.item.getDateTime) + " às " + DateFormat.jm().format(widget.item.getDateTime),
                      ),
                      trailing: FirebaseAuth.instance.currentUser.uid == widget.item.getUserId
                          ? PopupMenuButton(
                              child: IconButton(
                                iconSize: 32,
                                icon: Icon(Icons.more_vert),
                              ),
                              itemBuilder: (context) {
                                return [
                                  // PopupMenuItem(
                                  //   child: Text('Editar'),
                                  // ),
                                  PopupMenuItem(
                                    child: InkWell(
                                      child: Text('Excluir'),
                                      onTap: () {
                                        showMyDialog(widget.item, context, 'activity');
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
                        padding: const EdgeInsets.only(bottom: 15, left: 15),
                        child: Text(
                          widget.item.getTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.only(left: 15),
                        width: 170,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text("Distância"),
                                Text(
                                  (widget.item.getDistance / 1000).toStringAsFixed(2) + 'km',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text("Tempo"),
                                Text(
                                  printDuration(Duration(seconds: widget.item.getDuration), false),
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    //Image.network(widget.activity.imageUrl),
                    Container(
                      height: 250,
                      child: AbsorbPointer(
                        child: GoogleMap(
                          zoomControlsEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(widget.item.getCoordinates[0]['lat'], widget.item.getCoordinates[0]['lng']),
                            zoom: 13.0,
                          ),
                          polylines: createPolyLine(),
                          markers: createMarkers(widget.item),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? Center(
                      child: Container(
                        child: CircularProgressIndicator(),
                        margin: EdgeInsets.only(bottom: 15),
                      ),
                    )
                  : ButtonBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: [
                            FlatButton(
                              child: widget.item.currentUserLike ? Icon(Icons.thumb_up) : Icon(Icons.thumb_up_outlined),
                              onPressed: () async {
                                setState(() {
                                  if (widget.item.currentUserLike) {
                                    widget.item.likes -= 1;
                                  } else {
                                    widget.item.likes += 1;
                                  }
                                  widget.item.currentUserLike = !widget.item.currentUserLike;
                                });

                                await toggleLike(widget.item, !widget.item.currentUserLike);
                              },
                            ),
                            FlatButton(
                              child: Icon(Icons.comment_outlined),
                              onPressed: () {
                                Navigator.pushNamed(context, '/add_comment', arguments: widget.item).then((value) => setState(() {
                                      refreshCard();
                                    }));
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              child: widget.item.likes == 1
                                  ? Text(widget.item.likes.toString() + " curtida")
                                  : Text(widget.item.likes.toString() + " curtidas"),
                              onTap: () {
                                Navigator.pushNamed(context, '/likes', arguments: widget.item.getId);
                              },
                            ),
                            SizedBox(width: 20),
                            InkWell(
                              onTap: () {
                                // Navigator.pushNamed(context, '/show_comments', arguments: widget.item).then((value) => widget.notifyParent());
                                Navigator.pushNamed(context, '/show_comments', arguments: widget.item).then((value) => setState(() {
                                      refreshCard();
                                    }));
                              },
                              child: Text("${widget.item.getCommentsNumber} comentários"),
                            ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      );
    } else if (widget.item.getType == 'help') {
      return Center(
        child: Card(
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/help_card_details', arguments: [widget.item, _markersHelp]).then((value) => setState(() {
                    refreshCard();
                  }));
            },
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(widget.item.avatarUrl),
                          radius: 23,
                        ),
                        title: Text(
                          widget.item.getProfileName + " criou um pedido de ajuda",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          DateFormat.yMMMMd().format(widget.item.getDateTime) + " às " + DateFormat.jm().format(widget.item.getDateTime),
                        ),
                        trailing: FirebaseAuth.instance.currentUser.uid == widget.item.getUserId
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
                                          showMyDialog(widget.item, context, 'help');
                                        },
                                      ),
                                    )
                                  ];
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 15),
                    child: Text(
                      widget.item.getTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                      left: 15,
                    ),
                    child: Text(widget.item.getDescription),
                  ),
                ),
                Container(
                  height: 250,
                  child: AbsorbPointer(
                    child: GoogleMap(
                      markers: _markersHelp,
                      zoomControlsEnabled: false,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.item.latitude, widget.item.longitude),
                        zoom: 15.0,
                      ),
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
                    Navigator.pushNamed(context, '/show_map_screen', arguments: [widget.item.getLatitude, widget.item.getLongitude]);
                  },
                ),
                FirebaseAuth.instance.currentUser.uid != widget.item.userId
                    ? TextButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Mandar uma mensagem para " + widget.item.getProfileName + " ",
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
                              arguments: [widget.item.userId, widget.item.getProfileName, widget.item.avatarUrl]);
                        },
                      )
                    : SizedBox(height: 15),
              ],
            ),
          ),
        ),
      );
    }
    return null;
  }
}
