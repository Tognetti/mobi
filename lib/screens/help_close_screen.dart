import 'package:flutter/material.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';

class HelpCloseScreen extends StatefulWidget {
  @override
  _HelpCloseScreenState createState() => _HelpCloseScreenState();
}

class _HelpCloseScreenState extends State<HelpCloseScreen> {
  @override
  Widget build(BuildContext context) {
    FeedItemModel feedItem = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Encerrar pedido'),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 40, vertical: 25),
        child: Column(
          children: [
            Text(
              'Algum outro usuário te ajudou com o seu problema?',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/help_close_search', arguments: feedItem);
                  },
                  child: Card(
                    elevation: 3,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
                      child: Text(
                        "Sim",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () async {
                    await closeHelpRequest(feedItem, null, context);
                    Navigator.pushNamed(context, '/help_close_confirmation');
                  },
                  child: Card(
                    elevation: 3,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
                      child: Text(
                        "Não",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
