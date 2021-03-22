import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'globals.dart' as globals;

class PostWrite extends StatefulWidget {
  final String boardType;

  PostWrite({Key key, @required this.boardType,});

  @override
  _PostWriteState createState() => _PostWriteState(boardType: this.boardType,);
}

class _PostWriteState extends State<PostWrite> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  String boardType;

  _PostWriteState({this.boardType,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          '글 쓰기',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () {
              var data = {
                'boardType': boardType,
                'comments': 0,
                'content': contentController.text,
                'date': DateTime.now(),
                'isEdit': false,
                'like': 0,
                'region': globals.dbUser.getRegion(),
                'report': 0,
                'reportUserList': [],
                'title': titleController.text,
                'writer': globals.dbUser.getUID(),
              };

              if(boardType == 'anonymous') {
                String uid = globals.dbUser.getUID();
                data['writerNick'] = 'Anonymous';
                data['anonymousList'] = {'$uid': 'Anonymous(writer)'};
              }
              else {
                data['writerNick'] = globals.dbUser.getNickName();
              }
              Firestore.instance.collection('board').add(data);

              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(15.0, 8.0, 15.0, 8.0),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Title',
                  ),
                ),
                SizedBox(height: 8.0,),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Content',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}