import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:mobi/models/feed_item_model.dart';

class HelpCloseSearchScreen extends StatefulWidget {
  @override
  _HelpCloseScreenState createState() => _HelpCloseScreenState();
}

class _HelpCloseScreenState extends State<HelpCloseSearchScreen> {
  String searchString;
  FloatingSearchBarController controller;
  var results = [];

  @override
  void initState() {
    super.initState();
    controller = FloatingSearchBarController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FeedItemModel feedItem = ModalRoute.of(context).settings.arguments;

    Future search(query) async {
      results = [];

      var resultados = await FirebaseFirestore.instance
          .collection('users')
          .where("username", isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + 'z')
          .get();

      for (var user in resultados.docs) {
        results.add(
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.data()['image_url']),
              radius: 30,
            ),
            title: Text(
              user.data()['username'],
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              user['cidade'] + ", " + user['estado'],
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/help_close_user_confirmation',
                  arguments: [user.id, user['username'], user['image_url'], feedItem]);
            },
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Encerrar pedido'),
      ),
      body: FloatingSearchBar(
        isScrollControlled: true,
        automaticallyImplyBackButton: false,
        controller: controller,
        title: Text("Pesquisar..."),
        hint: '',
        builder: (context, transition) {
          return Container();
        },
        body: FloatingSearchBarScrollNotifier(
          child: SingleChildScrollView(
            child: Container(
              child: searchString == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Card(
                          elevation: 3,
                          margin: EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 20),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                            child: Text(
                              "Use a pesquisa para selecionar o usuário que te ajudou com o seu problema.",
                              style: TextStyle(
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    )
                  : FutureBuilder(
                      future: search(searchString),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.only(top: 70),
                            itemBuilder: (context, index) {
                              return results[index];
                            },
                            itemCount: results.length,
                          );
                        } else {
                          return Center(
                            // child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
            ),
          ),
        ),
        onSubmitted: (query) {
          setState(() {
            searchString = query;
          });
          controller.close();
        },
      ),
    );
  }
}
