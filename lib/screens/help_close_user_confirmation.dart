import 'package:flutter/material.dart';
import 'package:mobi/backoffice/utils.dart';
import 'package:mobi/models/feed_item_model.dart';

class HelpUserConfirmation extends StatefulWidget {
  @override
  _HelpUserConfirmationState createState() => _HelpUserConfirmationState();
}

class _HelpUserConfirmationState extends State<HelpUserConfirmation> {
  String message = '';
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    List<dynamic> args = ModalRoute.of(context).settings.arguments;
    String userId = args[0];
    String userName = args[1];
    String imageUrl = args[2];
    FeedItemModel feedItem = args[3];

    return Scaffold(
      appBar: AppBar(
        title: Text('Confimar usuário'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            height: 350,
            width: 350,
            child: Card(
              color: Colors.white,
              elevation: 10,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        userName,
                        style: TextStyle(fontSize: 23),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: TextFormField(
                        maxLines: 2,
                        decoration: InputDecoration(labelText: 'Deixe uma mensagem para ' + userName),
                        onSaved: (value) {
                          message = value;
                        },
                      ),
                    ),
                  ),
                  isLoading
                      ? Container(
                          margin: EdgeInsets.only(top: 5),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Container(
                          margin: EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            onPressed: () async {
                              _formKey.currentState.save();
                              setState(() {
                                isLoading = true;
                              });
                              await closeHelpRequest(feedItem, userId, context);
                              sendMessage(userId, 'Você ganhou 500 pontos de experiência por atender ao meu pedido de ajuda!');
                              if (message != '') {
                                sendMessage(userId, message);
                              }
                              setState(() {
                                isLoading = false;
                              });
                              Navigator.pushNamed(context, '/help_close_confirmation');
                            },
                            child: Text('Confirmar'),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
