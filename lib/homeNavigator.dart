import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:badges/badges.dart';
import 'homePage.dart';
import 'boardHome.dart';
import 'globals.dart' as globals;
import 'searchPage.dart';
import 'personalInfo.dart';
import 'notificationBody.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class homeNavigator extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}
class _MyHomePageState extends State<homeNavigator> {
  final GlobalKey<homePageState> _homePageStateKey= GlobalKey();
  final GlobalKey<searchPageState> _searchPageStateKey = GlobalKey();
  final GlobalKey<boardHomeState> _boardHomeStateKey = GlobalKey();
  final GlobalKey<NotificationBodyState> _NotificationBodyStateKey = GlobalKey();
  final GlobalKey<personalInfoState> _personalInfoStateKey= GlobalKey();
  int _selectedIndex = 0;
  List _widgetOptions;
  List _widgetKeys;

  refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      homePage(key:_homePageStateKey),
      searchPage(key:_searchPageStateKey),
      boardHome(key:_boardHomeStateKey),
      NotificationBody(key:_NotificationBodyStateKey),
      personalInfo(key:_personalInfoStateKey, refresh: this.refresh,),
    ];
    _widgetKeys =[
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
              'Project Locals',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            actions: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                child: InkWell(
                  child: Text(
                    globals.dbUser.getSelectedRegion(),
                    style: TextStyle(color: Colors.black),
                  ),
                  onTap: ()=>Navigator.pushNamed(context, '/naverMap')
                      .then((value)async{
                        if(value!=null){
                          await globals.dbUser.userOnDB.updateData({
                            "region":value
                          }).then((value) async {
                            await globals.dbUser.getUserFromDB();
                            setState(() {});
                          });
                          _widgetKeys.elementAt(_selectedIndex).currentState.Refresh();
                        }
                      }),
                ),
              )
            ],
          ),
          bottomNavigationBar:BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.withOpacity(.60),
            selectedFontSize: 15,
            unselectedFontSize: 14,
            currentIndex: _selectedIndex,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (int index){
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                  label: "home",
                  icon: Icon(Icons.home_outlined)
              ),
              BottomNavigationBarItem(
                  label: "search",
                  icon: Icon(Icons.search)
              ),
              BottomNavigationBarItem(
                  label: "board list",
                  icon: Icon(CupertinoIcons.list_dash)
              ),
              BottomNavigationBarItem(
                  label: "messages",
                  icon: _messageIcon(context),
              ),
              BottomNavigationBarItem(
                  label: "personal info",
                  icon: Icon(CupertinoIcons.person)
              ),
            ],
          ),
          body: appBody()
      );
  }
  Widget appBody(){
    return Center(
      child: _widgetOptions.elementAt(_selectedIndex),
    );
  }
  Widget _messageIcon(BuildContext context) {
    return StreamBuilder(
      stream: Firestore.instance.collection('user').document(globals.dbUser.getUID()).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if(!snapshot.hasData) return Container();

        int unread = snapshot.data['unreadCount'];

        if(unread >= 1) {
          return Badge(
            badgeContent: Text('$unread'),
            child: Icon(CupertinoIcons.paperplane),
          );
        }
        else return Icon(CupertinoIcons.paperplane);
      },
    );
  }




}