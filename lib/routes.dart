import 'package:flutter/material.dart';
import 'package:project_locals/loginPage.dart';
import 'package:project_locals/homeNavigator.dart';
import 'boardHome.dart';

final routes = {
  '/login': (BuildContext context) => loginPage(),
  '/homeNavigator': (BuildContext context) => homeNavigator(),
  '/board': (BuildContext context) => boardHome(),
};