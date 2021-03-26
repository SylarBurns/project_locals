import 'package:flutter/material.dart';

import 'freeBoard.dart';

class boardHome extends StatefulWidget {
  const boardHome({Key key}) : super(key: key);
  @override
  boardHomeState createState() => boardHomeState();
}

class boardHomeState extends State<boardHome> {
  Refresh(){setState(() {});}
  @override
  Widget build(BuildContext context) {
    List<String> boardNames = ['자유 게시판', '익명 게시판', 'Lost & Found', '홍보 게시판'];
    List<String> boardTypes = ['free', 'anonymous', 'lostAndFound', 'promo'];

    return Scaffold(
      body: ListView.builder(
        itemCount: boardNames.length,
        itemBuilder: (context, index) {
          String boardName = boardNames[index];
          String boardT = boardTypes[index];
          return ListTile(
            leading: Icon(Icons.push_pin_outlined),
            title: Text('$boardName'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FreeBoard(boardName: boardName, boardType: boardT,)),
              );
            }
          );
        },
      ),
    );
  }
}