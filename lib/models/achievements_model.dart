import 'package:flutter/material.dart';

class AchievementModel {
  final String id;
  final String imageUrl;
  final String name;
  final String description;
  final int target;

  AchievementModel({
    @required this.id,
    @required this.name,
    @required this.imageUrl,
    @required this.description,
    @required this.target,
  });

  String get getName {
    return name;
  }

  String get getImageUrl {
    return imageUrl;
  }

  String get getDescription {
    return description;
  }

  String get getId {
    return id;
  }
}