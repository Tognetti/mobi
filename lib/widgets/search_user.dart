import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Search extends SearchDelegate {
  String get searchFieldLabel => 'Pesquisar usuários';
  var results = [];

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context).copyWith(
      textTheme: TextTheme(
        headline6: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    assert(theme != null);
    return theme;
  }

  // @override
  // TextStyle get searchFieldStyle => TextStyle(
  //       color: Colors.black,
  //       fontSize: 18.0,
  //       fontWeight: FontWeight.w500,
  //     );

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          query = "";
        },
      )
    ];
    throw UnimplementedError();
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    throw UnimplementedError();
  }

  Future search(searchData, context) async {
    results = [];
    var resultados = await FirebaseFirestore.instance
        .collection('users')
        .where("username", isGreaterThanOrEqualTo: searchData)
        .where('username', isLessThan: searchData + 'z')
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
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: search(query, context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (results.length == 0) {
            return Center(child: Text("Nenhum usuário encontrado"));
          } else {
            return ListView.builder(
              itemBuilder: (context, index) {
                return results[index];
              },
              itemCount: results.length,
            );
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column();
    throw UnimplementedError();
  }
}
