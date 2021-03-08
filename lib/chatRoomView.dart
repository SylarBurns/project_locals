import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;
final db = Firestore.instance;
class chatRoomView extends StatefulWidget{
  final String chatRoomID;
  final String chatRoomName;
  chatRoomView({Key key, @required this.chatRoomID, @required this.chatRoomName});
  @override
  _chatRoomViewState createState() => _chatRoomViewState(chatRoomID: this.chatRoomID, chatRoomName:this.chatRoomName);
}

class _chatRoomViewState extends State<chatRoomView> {
  String chatRoomID;
  String chatRoomName;
  _chatRoomViewState({Key key, this.chatRoomID, this.chatRoomName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chatRoomName),
      ),
      body: StreamBuilder(
        stream: db.collection('chatroom').document(chatRoomID).collection('messages').orderBy('date').snapshots(),
        builder: (context, snapshots){
          return ListView.builder(
              itemCount: snapshots.data.documents.length,
              itemBuilder: (context, index){
                return chatMessageItem(context, snapshots.data.documents[index]);
              }
          );
        }
      ),
    );
  }
  Widget chatMessageItem(BuildContext context, DocumentSnapshot document){
    return Container(
      padding: EdgeInsets.all(8),
      alignment: document['sender']==globals.dbUser.getUID()?Alignment.topRight:Alignment.topLeft,
      child: Container(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                document["content"],
                style: TextStyle(fontSize: 20),
            ),
          ),
          color: document['sender']==globals.dbUser.getUID() ? Colors.lightBlue : Colors.white,
        ),
      ),
    );
  }
}