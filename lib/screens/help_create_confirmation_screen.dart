import 'package:flutter/material.dart';

class HelpConfirmationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pedido de ajuda criado"),
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pushNamedAndRemoveUntil(context, '/main_feed', (route) => false);
          return Future.value(false);
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Image.asset(
                  'lib/assets/images/bike1.png',
                  scale: 7,
                ),
                Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          "Seu pedido de ajuda foi criado e um outro usuário irá entrar em contato caso possa te ajudar.",
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Lembre-se de encerrar o seu pedido de ajuda quando o seu problema for resolvido.",
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        RaisedButton(
                          child: Text(
                            "Voltar ao início",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(context, '/main_feed', (route) => false);
                          },
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
