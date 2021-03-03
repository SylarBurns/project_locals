import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

UserInfo dbUser;

class UserInfo{
  FirebaseUser _user;
  String _nickName = "Loading..";
  String _region = "fake region";
  UserInfo(FirebaseUser newUser) {
    _user = newUser;
  }
  Future getUserFromDB() async{
    print("User ID: "+_user.uid);
    DocumentSnapshot dbUser = await Firestore.instance.collection('user').document(_user.uid).get();
    print(dbUser.data["region"]);
    _nickName = await dbUser.data["nickName"];
    _region = await dbUser.data["region"];
  }

  String getNickName() {
    return _nickName;
  }

  String getRegion() {
    return _region;
  }
}