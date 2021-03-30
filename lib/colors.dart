import 'package:flutter/material.dart';
final appThemeData theme_1 = themeData_1();
final appThemeData theme_2 = themeData_2();
final appThemeData theme_3 = themeData_3();
class appThemeData{
  Color accent;
  Color primary;
  Color secondary;
  Color tertiary;
  Color background;
  Color backgroundSecondary;
  Color error;
}
class themeData_1 extends appThemeData{
  Color accent = Color(0xFF003049);
  Color primary = Color(0xFFD62828);
  Color secondary = Color(0xFFF77F00);
  Color tertiary = Color(0xFFFCBF49);
  Color background = Color(0xFFFFFFFF);
  Color backgroundSecondary = Color(0xFFFFFFFF);
  Color error = Color(0xFFC5032B);
}
class themeData_2 extends appThemeData{
  Color accent = Color(0xFF331832);
  Color primary = Color(0xFFD81E5B);
  Color secondary = Color(0xFFF0544F);
  Color tertiary = Color(0xFFC6D8D3);
  Color background = Color(0xFFFFFFFF);
  Color backgroundSecondary = Color(0xFFFDF0D5);
  Color error = Color(0xFFC5032B);
}
class themeData_3 extends appThemeData{
  Color accent = Color(0xFF054A91);
  Color primary = Color(0xFF3E7CB1);
  Color secondary = Color(0xFF81A4CD);
  Color tertiary = Color(0xFFDBE4EE);
  Color background = Color(0xFFFFFFFF);
  Color backgroundSecondary = Color(0xFFDBE4EE);
  Color error = Color(0xFFC5032B);
}