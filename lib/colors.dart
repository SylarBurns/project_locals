import 'package:flutter/material.dart';
appThemeData theme_1;
appThemeData theme_2;
appThemeData theme_3;
appThemeData theme_4;
appThemeData theme_5;
appThemeData theme_6;
List<appThemeData> themeDataList =[
  theme_1=themeData_1(),
  theme_2=themeData_2(),
  theme_3=themeData_3(),
  theme_4=themeData_4(),
  theme_5=themeData_5(),
];
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
class themeData_4 extends appThemeData{
  Color accent = Color(0xFF0F5257);
  Color primary = Color(0xFF0B3142);
  Color secondary = Color(0xFF49a078);
  Color tertiary = Color(0xFFC6B9CD);
  Color background = Color(0xFFFFFFFF);
  Color backgroundSecondary = Color(0xFF73ab77);
  Color error = Color(0xFFC5032B);
}
class themeData_5 extends appThemeData{
  Color accent = Color(0xFF210B2C);
  Color primary = Color(0xFF55286F);
  Color secondary = Color(0xFFBC96E6);
  Color tertiary = Color(0xFFAE759F);
  Color background = Color(0xFFFFFFFF);
  Color backgroundSecondary = Color(0xFFD8B4E2);
  Color error = Color(0xFFC5032B);
}