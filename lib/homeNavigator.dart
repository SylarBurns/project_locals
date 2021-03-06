import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'homePage.dart';
import 'boardHome.dart';
import 'globals.dart' as globals;
import 'searchPage.dart';
import 'personalInfo.dart';
import 'notificationBody.dart';

class homeNavigator extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<homeNavigator> {
  final GlobalKey<homePageState> _homePageStateKey = GlobalKey();
  final GlobalKey<searchPageState> _searchPageStateKey = GlobalKey();
  final GlobalKey<boardHomeState> _boardHomeStateKey = GlobalKey();
  final GlobalKey<NotificationBodyState> _NotificationBodyStateKey =
      GlobalKey();
  final GlobalKey<personalInfoState> _personalInfoStateKey = GlobalKey();
  int _selectedIndex = 0;
  List<Widget> _widgetOptions;
  List _widgetKeys;

  refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      homePage(key: _homePageStateKey),
      searchPage(key: _searchPageStateKey),
      boardHome(key: _boardHomeStateKey),
      NotificationBody(key: _NotificationBodyStateKey),
      personalInfo(
        key: _personalInfoStateKey,
        refresh: this.refresh,
      ),
    ];
    _widgetKeys = [
      _homePageStateKey,
      _searchPageStateKey,
      _boardHomeStateKey,
      _NotificationBodyStateKey,
      _personalInfoStateKey,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            '지역감정',
            style: TextStyle(fontFamily: 'DXMobrRExtraBold'),
          ),
          actions: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              child: InkWell(
                child: Text(
                  globals.dbUser.getSelectedRegion(),
                  style: TextStyle(
                      color: Theme.of(context).accentTextTheme.bodyText1.color),
                ),
                onTap: () => Navigator.pushNamed(context, '/naverMap')
                    .then((value) async {
                  if (value != null) {
                    await globals.dbUser.userOnDB
                        .updateData({"region": value}).then((value) async {
                      await globals.dbUser.getUserFromDB();
                      setState(() {});
                    });
                    Phoenix.rebirth(context);
                  }
                }),
              ),
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 16,
          unselectedFontSize: 14,
          currentIndex: _selectedIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
                label: "home", icon: Icon(Icons.home_outlined)),
            BottomNavigationBarItem(label: "search", icon: Icon(Icons.search)),
            BottomNavigationBarItem(
                label: "board list", icon: Icon(CupertinoIcons.list_dash)),
            BottomNavigationBarItem(
              label: "messages",
              icon: _messageIcon(context),
            ),
            BottomNavigationBarItem(
                label: "personal info", icon: Icon(CupertinoIcons.person)),
          ],
        ),
        body: appBody());
  }

  Widget appBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: _widgetOptions,
    );
  }

  Widget _messageIcon(BuildContext context) {
    return StreamBuilder(
      stream: Firestore.instance
          .collection('user')
          .document(globals.dbUser.getUID())
          .snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (!snapshot.hasData) return Container();

        int unread = snapshot.data['unreadCount'];

        if (unread >= 1) {
          return Badge(
            badgeContent: Text('$unread'),
            child: Icon(CupertinoIcons.paperplane),
          );
        } else
          return Icon(CupertinoIcons.paperplane);
      },
    );
  }
}
