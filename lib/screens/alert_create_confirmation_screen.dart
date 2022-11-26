import 'package:flutter/material.dart';

class AlertConfirmationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Alerta criado"),
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pushNamedAndRemoveUntil(context, '/main_feed', (route) => false);
          return Future.value(false);
        },
        child: Center(
          child: Column(
            children: [
              Image.asset(
                'lib/assets/images/bike1.png',
                scale: 7,
              ),
              Card(
                margin: EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(13),
                ),
                elevation: 3,
                color: Colors.green,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '+ 100XP!',
                        style: TextStyle(
                          fontSize: 21,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
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
                        "O alerta foi criado com sucesso.",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Obrigado por ajudar a comunidade!",
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
