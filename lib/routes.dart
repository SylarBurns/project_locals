import 'package:flutter/material.dart';
import 'package:project_locals/loginPage.dart';
import 'package:project_locals/homeNavigator.dart';
final routes = {
  '/': (BuildContext context) => loginPage(),
  '/homeNavigator': (BuildContext context) => homeNavigator(),
};