import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_locals/colors.dart';
import 'package:loading_animations/loading_animations.dart';

UserInfo dbUser;

class UserInfo {
  FirebaseUser _user;
  DocumentReference userOnDB;
  String _nickName = "Loading..";
  String _region = "fake region";
  String _selectedRegion = "fake region";
  UserInfo(FirebaseUser newUser) {
    _user = newUser;
  }
  Future getUserFromDB() async {
    print("User ID: " + _user.uid);
    DocumentSnapshot dbUser =
        await Firestore.instance.collection('user').document(_user.uid).get();
    userOnDB = Firestore.instance.collection('user').document(_user.uid);
    print(dbUser.data["region"]);
    _nickName = await dbUser.data["nickName"];
    _region = await dbUser.data["region"];
    _selectedRegion = await dbUser.data['region'];
  }

  String getNickName() {
    return _nickName;
  }

  String getRegion() {
    return _region;
  }

  String getUID() {
    return _user.uid;
  }

  String getSelectedRegion() {
    return _selectedRegion;
  }

  bool getAuthority() {
    return _region == _selectedRegion ? true : false;
  }

  void setSelectedRegion(String region) {
    _selectedRegion = region;
  }

  void setNickName(String nickName) {
    _nickName = nickName;
  }
}

Widget getLoadingAnimation(BuildContext context) {
  return Center(
      child: LoadingBouncingGrid.square(
    inverted: true,
    backgroundColor: Theme.of(context).primaryColor,
  ));
}
