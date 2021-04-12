import 'package:flutter/material.dart';
import 'package:project_locals/routes.dart';
import 'package:project_locals/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() => runApp(Phoenix(child: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData appTheme;
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    await SharedPreferences.getInstance().then((preference) {
      setState(() {
        appTheme = _buildTheme(
            themeDataList.elementAt(preference.getInt('ThemeIndex') ?? 0));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      title: 'ProjectLocals',
      routes: routes,
    );
  }
}

ThemeData _buildTheme(appThemeData data) {
  ThemeData base;
  if (data.islight) {
    base = ThemeData.light();
  } else {
    base = ThemeData.dark();
  }
  base.textTheme.apply(fontFamily: 'NotoSansKR');
  base.primaryTextTheme.apply(fontFamily: 'NotoSansKR');
  base.accentTextTheme.apply(fontFamily: 'NotoSansKR');
  return base.copyWith(
    accentColor: data.accent,
    primaryColor: data.primary,
    backgroundColor: data.background,
    primaryColorDark: data.backgroundSecondary,
    accentTextTheme: base.textTheme.copyWith(
      bodyText1: TextStyle(color: data.accent),
      bodyText2: TextStyle(color: data.primary),
    ),
    textTheme: base.textTheme.copyWith(
      headline1: TextStyle(color: data.accent),
      headline2: TextStyle(color: data.accent),
      headline3: TextStyle(color: data.accent),
      headline4: TextStyle(color: data.accent),
      headline5: TextStyle(color: data.accent),
      headline6: TextStyle(color: data.accent),
      bodyText1: TextStyle(color: data.accent),
      bodyText2: TextStyle(color: data.accent),
      subtitle1: TextStyle(color: data.accent),
      subtitle2: TextStyle(color: data.accent),
      caption: TextStyle(color: data.accent),
      button: TextStyle(color: data.accent),
      overline: TextStyle(color: data.accent),
    ),
    buttonTheme: base.buttonTheme.copyWith(
      buttonColor: data.backgroundSecondary,
      colorScheme: base.colorScheme.copyWith(
        primary: data.primary,
        secondary: data.backgroundSecondary,
      ),
    ),
    buttonBarTheme: base.buttonBarTheme.copyWith(
      buttonTextTheme: ButtonTextTheme.accent,
    ),
    bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
      backgroundColor: data.backgroundSecondary,
      selectedItemColor: data.accent,
      unselectedItemColor: data.primary.withOpacity(.60),
    ),
    appBarTheme: base.appBarTheme.copyWith(
        color: data.backgroundSecondary,
        textTheme: TextTheme(
          headline6: TextStyle(color: data.accent, fontSize: 20),
        ),
        iconTheme: IconThemeData(color: data.accent),
        actionsIconTheme: IconThemeData(color: data.accent),
        elevation: 5),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: data.primary,
    ),
    scaffoldBackgroundColor: data.background,
    cardColor: data.backgroundSecondary,
    textSelectionColor: data.tertiary,
    errorColor: data.error,
  );
}
