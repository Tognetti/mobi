import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobi/models/achievements_model.dart';

class UserAchievements extends StatefulWidget {
  UserAchievements(this.userAchievements, this.allAchievements);

  final List<AchievementModel> userAchievements;
  final List<AchievementModel> allAchievements;

  @override
  _UserAchievementsState createState() => _UserAchievementsState();
}

class _UserAchievementsState extends State<UserAchievements> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          child: Expanded(
            child: widget.userAchievements.length == 0
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/assets/images/bike6.png',
                        scale: 7,
                      ),
                      Container(
                        padding: EdgeInsets.only(bottom: 50),
                        width: 350,
                        child: Text(
                          "Registre sua primeira atividade e contribua com a comunidade para começar a desbloquear conquistas!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: widget.userAchievements.length,
                    itemBuilder: (BuildContext context, int i) {
                      return GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Container(
                                height: 220,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 15),
                                        child: Image.network(
                                          widget.userAchievements[i].getImageUrl,
                                          height: 120,
                                          width: 120,
                                        ),
                                      ),
                                      Text(
                                        widget.userAchievements[i].getName,
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                      Flexible(
                                        child: Text(
                                          widget.userAchievements[i].getDescription,
                                          style: TextStyle(fontSize: 17),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.all(20),
                          width: 80,
                          height: 80,
                          child: Column(
                            children: <Widget>[
                              Expanded(child: Image.network(widget.userAchievements[i].getImageUrl)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        widget.userAchievements.length != 0
            ? Container(
                margin: EdgeInsets.only(bottom: 20, top: 20),
                alignment: Alignment.center,
                child: Text(
                  "Você desbloqueou ${widget.userAchievements.length} das ${widget.allAchievements.length} conquistas",
                  style: TextStyle(fontSize: 17),
                ),
              )
            : Container(),
      ],
    );
  }
}
