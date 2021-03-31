import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_locals/routes.dart';
import 'package:project_locals/loginPage.dart';
import 'package:project_locals/homeNavigator.dart';
import 'package:project_locals/colors.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _themeData_3,
      title: 'ProjectLocals',
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
final ThemeData _themeData_1 = _buildTheme(theme_1);
final ThemeData _themeData_2 = _buildTheme(theme_2);
final ThemeData _themeData_3 = _buildTheme(theme_3);
ThemeData _buildTheme(appThemeData data){
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    accentColor: data.accent,
    primaryColor: data.primary,
    backgroundColor: data.background,
    textTheme: base.textTheme.copyWith(
      headline6: TextStyle(color: data.accent),
      button: TextStyle(color:data.accent),
      bodyText1: TextStyle(color: data.accent),
      bodyText2: TextStyle(color: data.accent),
    ),
    buttonTheme: base.buttonTheme.copyWith(
      buttonColor: data.backgroundSecondary,
      colorScheme: base.colorScheme.copyWith(
        primary: data.primary,
        secondary: data.backgroundSecondary,
      ),
    ),
    buttonBarTheme: base.buttonBarTheme.copyWith(
      buttonTextTheme:ButtonTextTheme.accent,
    ),
    bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
      backgroundColor: data.backgroundSecondary,
      selectedItemColor: data.accent,
      unselectedItemColor: data.primary.withOpacity(.60),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      color: data.backgroundSecondary,
      textTheme: TextTheme(
        headline6: TextStyle(
            color: data.accent,
            fontSize: 20
        ),
      ),
      iconTheme: IconThemeData(color: data.accent),
      actionsIconTheme: IconThemeData(color: data.accent),
      elevation: 5
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: data.primary,
    ),
    scaffoldBackgroundColor: data.background,
    cardColor: data.backgroundSecondary,
    textSelectionColor:data.secondary,
    errorColor:data.error,
  );
}