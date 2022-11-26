import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:flutter/material.dart';

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
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
            Navigator.pushNamed(context, '/profile', arguments: user.id);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesquisar usuário'),
      ),
      body: FloatingSearchBar(
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
                  ? Center()
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
