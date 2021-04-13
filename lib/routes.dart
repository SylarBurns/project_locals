import 'package:flutter/material.dart';
import 'package:project_locals/loginPage.dart';
import 'package:project_locals/homeNavigator.dart';
import 'boardHome.dart';
import 'package:project_locals/registration.dart';
import 'package:project_locals/likedList.dart';
import 'package:project_locals/naver_map.dart';
import 'package:project_locals/selectThemeColor.dart';
import 'package:project_locals/wroteList.dart';

final routes = {
  '/': (BuildContext context) => loginPage(),
  '/homeNavigator': (BuildContext context) => homeNavigator(),
  '/board': (BuildContext context) => boardHome(),
  '/registration': (BuildContext context) => registration(),
  '/wroteList': (BuildContext context) => wroteList(),
  '/likedList': (BuildContext context) => likeList(),
  '/naverMap': (BuildContext context) => naverMap(),
  '/selectThemeColor': (BuildContext context) => selectThemeColor(),
};
