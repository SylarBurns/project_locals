# 지역감정

지역 주민과 교류하고 유대관계를 쌓아가기 위한 앱

## 주요 기능

|구글 로그인|실시간 인기 글|게시판 별 최신 글|
|:---:|:---:|:---:|
|<image src="https://user-images.githubusercontent.com/41365906/114262672-368e7680-9a1c-11eb-91aa-fffc143d8175.png" width="270" height="480" >|<image src="https://user-images.githubusercontent.com/41365906/114262676-3d1cee00-9a1c-11eb-9038-96fd600ab181.png" width="270" height="480" > |<image src="https://user-images.githubusercontent.com/41365906/114262679-3ee6b180-9a1c-11eb-8977-5bbc158fdf99.png" width="270" height="480" > |
|**검색 기능**|**지역 인증**|**알림 기능**|
|<image src="https://user-images.githubusercontent.com/41365906/114262680-3f7f4800-9a1c-11eb-9a5b-6009034e355c.png" width="270" height="480" >|<image src="https://user-images.githubusercontent.com/41365906/114263301-a5210380-9a1f-11eb-922a-b8cfb6e97bb1.png" width="270" height="480" > |<image src="https://user-images.githubusercontent.com/41365906/114262683-427a3880-9a1c-11eb-9fa6-af3ade9eebf4.png" width="270" height="480" > |
|**채팅 기능**|**다양한 테마**|**댓글과 대댓글**|
|<image src="https://user-images.githubusercontent.com/41365906/114262684-43ab6580-9a1c-11eb-815f-5a765612cc2d.png" width="270" height="480" >|<image src="https://user-images.githubusercontent.com/41365906/114262685-44dc9280-9a1c-11eb-9577-41e61acf2231.png" width="270" height="480" > |<image src="https://user-images.githubusercontent.com/41365906/114262689-46a65600-9a1c-11eb-9c6a-a6a447fde4fb.png" width="270" height="480" > |

## Libraries
  * [cloud_firestore: ^0.13.4+2](https://pub.dev/packages/cloud_firestore/versions/0.13.4+2)
  * [intl: ^0.16.1](https://pub.dev/packages/intl/versions/0.16.1)
  * [firebase_auth: ^0.15.5+3](https://pub.dev/packages/firebase_auth/versions/0.15.5+3)
  * [google_sign_in: ^4.4.1](https://pub.dev/packages/google_sign_in/versions/4.4.1)
  * [rxdart: ^0.23.0](https://pub.dev/packages/rxdart/versions/0.23.0)
  * [badges: ^1.2.0](https://pub.dev/packages/badges/versions/1.2.0)
  * [scrollable_positioned_list: ^0.1.10](https://pub.dev/packages/scrollable_positioned_list/versions/0.1.10)
  * [firebase_storage: ^3.0.8](https://pub.dev/packages/firebase_storage/versions/3.0.8)
  * [image_picker: ^0.6.7+22](https://pub.dev/packages/image_picker/versions/0.6.7+22)
  * [full_screen_image: ^1.0.2](https://pub.dev/packages/full_screen_image/versions/1.0.2)
  * [naver_map_plugin: ^0.9.6](https://pub.dev/packages/naver_map_plugin/versions/0.9.6)
  * [http: ^0.12.0+2](https://pub.dev/packages/http/versions/0.12.0+2)
  * [loading_animations: ^2.1.0](https://pub.dev/packages/loading_animations/versions/2.1.0)
  * [firebase_core: ^0.4.0+9](https://pub.dev/packages/firebase_core/versions/0.4.0+9)
  * [firebase_analytics: ^5.0.6](https://pub.dev/packages/firebase_analytics/versions/5.0.6)
  * [shared_preferences: ^0.5.3+2](https://pub.dev/packages/shared_preferences/versions/0.5.3+2)
  * [flutter_phoenix: ^0.1.0](https://pub.dev/packages/flutter_phoenix/versions/0.1.0)
  * [cached_network_image: ^2.5.1](https://pub.dev/packages/cached_network_image/versions/2.5.1)
## Routes
```dart
import 'package:flutter/material.dart';
import 'package:project_locals/loginPage.dart';
import 'package:project_locals/homeNavigator.dart';
import 'boardHome.dart';
import 'package:project_locals/registration.dart';
import 'package:project_locals/likedList.dart';
import 'package:project_locals/naver_map.dart';
import 'package:project_locals/selectThemeColor.dart';
final routes = {
  '/': (BuildContext context) => loginPage(),
  '/homeNavigator': (BuildContext context) => homeNavigator(),
  '/board': (BuildContext context) => boardHome(),
  '/registration': (BuildContext context)=> registration(),
  '/likedList':(BuildContext context)=> likeList(),
  '/naverMap' :(BuildContext context)=> naverMap(),
  '/selectThemeColor':(BuildContext context)=>selectThemeColor(),
};
```
## Main
```dart
import 'package:flutter/material.dart';
import 'package:project_locals/routes.dart';
import 'package:project_locals/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
void main() => runApp(Phoenix(child:MyApp()));

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
    await SharedPreferences.getInstance().then((preference){
      setState(() {
        appTheme = _buildTheme(themeDataList.elementAt(preference.getInt('ThemeIndex') ?? 0));
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
```
