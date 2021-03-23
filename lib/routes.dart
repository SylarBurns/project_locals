import 'package:flutter/material.dart';
import 'package:project_locals/loginPage.dart';
import 'package:project_locals/homeNavigator.dart';
import 'boardHome.dart';
import 'package:project_locals/registration.dart';
import 'package:project_locals/likedList.dart';
final routes = {
  '/': (BuildContext context) => loginPage(),
  '/homeNavigator': (BuildContext context) => homeNavigator(),
  '/board': (BuildContext context) => boardHome(),
  '/registration': (BuildContext context)=> registration(),
  '/likedList':(BuildContext context)=> likeList(),
};