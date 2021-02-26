import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'homePage.dart';
import 'boardHome.dart';



class homeNavigator extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<homeNavigator> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              'Project Locals',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          backgroundColor: Colors.white,
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
    Text(
      'Search',
      style: TextStyle(fontSize: 30,),
    ),
    boardHome(),
    Text(
      'messages',
      style: TextStyle(fontSize: 30,),
    ),
    Text(
      'personal info',
      style: TextStyle(fontSize: 30,),
    ),
  ];
}


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