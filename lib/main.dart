import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_locals/routes.dart';
import 'package:project_locals/loginPage.dart';
import 'package:project_locals/homeNavigator.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProjectLocals',
      home: homeNavigator(),
      initialRoute: '/login',
      onGenerateRoute: _getRoute,
      routes: routes,
    );
  }
  Route<dynamic> _getRoute(RouteSettings settings){
    if(settings.name != '/login'){
      return null;
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => loginPage(),
      fullscreenDialog: true,
    );
  }
}
