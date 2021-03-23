import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

import 'homePage.dart';
import 'boardHome.dart';
import 'globals.dart' as globals;
import 'searchPage.dart';
import 'chatRoomList.dart';
import 'personalInfo.dart';
final FirebaseAuth _auth = FirebaseAuth.instance;

class homeNavigator extends StatefulWidget {
  // void refresh() {
  //   setState(() {
  //
  //   });
  // }

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<homeNavigator> {
  // UserInfo dbUser;
  int _selectedIndex = 0;
  // void getUser() async{
  //   FirebaseUser currentUser = await _auth.currentUser();
  //   setState(() {
  //     if(currentUser != null){
  //       dbUser = new UserInfo(currentUser);
  //       dbUser.getUserFromDB();
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // if(dbUser == null)getUser();
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
                    globals.dbUser.getRegion(),
                    style: TextStyle(color: Colors.black),
                  ),
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
                  icon: Icon(CupertinoIcons.paperplane)
              ),
              BottomNavigationBarItem(
                  label: "personal info",
                  icon: Icon(CupertinoIcons.person)
              ),
            ],
          ),
          body: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          )
      );
  }
  List _widgetOptions = [
    homePage(),
    searchPage(),
    boardHome(),
    chatRoomList(),
    personalInfo(),
  ];
}
// class UserInfo{
//   FirebaseUser _user;
//   String _nickName = "Loading..";
//   String _region = "Loading..";
//   UserInfo(FirebaseUser newUser) {
//     _user = newUser;
//   }
//   void getUserFromDB() async{
//     print("User ID: "+_user.uid);
//     DocumentSnapshot dbUser = await Firestore.instance.collection('user').document(_user.uid).get();
//     print(dbUser.data["region"]);
//     _nickName = dbUser.data["nickName"];
//     _region = dbUser.data["region"];
//   }
// }

class Record_post {
  final String name;
  final int votes;
  final DocumentReference reference;

  Record_post.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

  Record_post.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);
  @override
  String toString() => "Record<$name:$votes>";
}