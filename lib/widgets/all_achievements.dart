import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobi/models/achievements_model.dart';

class AllAchievements extends StatefulWidget {
  AllAchievements(this.allAchievements);

  final List<AchievementModel> allAchievements;

  @override
  _AllAchievementsState createState() => _AllAchievementsState();
}

class _AllAchievementsState extends State<AllAchievements> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
        ),
        itemCount: widget.allAchievements.length,
        padding: EdgeInsets.only(top: 15, bottom: 75),
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
                              widget.allAchievements[i].getImageUrl,
                              height: 120,
                              width: 120,
                            ),
                          ),
                          Text(
                            widget.allAchievements[i].getName,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Flexible(
                            child: Text(
                              widget.allAchievements[i].getDescription,
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
              child: Column(
                children: <Widget>[
                  Image.network(
                    widget.allAchievements[i].getImageUrl,
                    height: 80,
                    width: 80,
                  ),
                  Container(
                    child: Text(
                      widget.allAchievements[i].getName,
                      textAlign: TextAlign.center,
                    ),
                    width: 100,
                    padding: EdgeInsets.only(top: 5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
