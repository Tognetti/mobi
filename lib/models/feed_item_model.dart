import 'package:flutter/material.dart';

class FeedItemModel {
  final String profileName;
  final String userId;
  final String activityTitle;
  final String activityDescription;
  final String imageUrl;
  final String avatarUrl;
  final String type;
  final double latitude;
  final double longitude;
  final DateTime dateTime;
  final List coordinates;
  int likes;
  final String id;
  List likesUsers;
  bool currentUserLike;
  final double distance;
  final int duration;
  final String parentId;
  int comments;

  FeedItemModel({
    @required this.id,
    @required this.profileName,
    @required this.imageUrl,
    @required this.activityTitle,
    this.activityDescription,
    this.avatarUrl,
    this.type,
    this.dateTime,
    this.coordinates,
    this.likes,
    this.likesUsers,
    this.currentUserLike,
    this.distance,
    this.duration,
    this.userId,
    this.parentId,
    this.latitude,
    this.longitude,
    this.comments,
  });

  String get getId {
    return id;
  }

  String get getProfileName {
    return profileName;
  }

  String get getTitle {
    return activityTitle;
  }

  String get getType {
    return type;
  }

  String get getDescription {
    return activityDescription;
  }

  DateTime get getDateTime {
    return dateTime;
  }

  String get getImageUrl {
    return imageUrl;
  }

  List get getCoordinates {
    return coordinates;
  }

  int get getLikes {
    return likes;
  }

  set setLikes(int likes) {
    this.likes = likes;
  }

  List get getUserLikes {
    return likesUsers;
  }

  set setUserLikes(List likesUsers) {
    this.likesUsers = likesUsers;
  }

  bool get getCurrentUserLike {
    return currentUserLike;
  }

  set setCurrentUserLike(bool currentUserLike) {
    this.currentUserLike = currentUserLike;
  }

  double get getDistance {
    return distance;
  }

  int get getDuration {
    return duration;
  }

  String get getUserId {
    return userId;
  }

  String get getParentId {
    return parentId;
  }

  double get getLatitude {
    return latitude;
  }

  double get getLongitude {
    return longitude;
  }

  int get getCommentsNumber {
    return comments;
  }

  set setCommentsNumber(int n) {
    this.comments = n;
  }
}
