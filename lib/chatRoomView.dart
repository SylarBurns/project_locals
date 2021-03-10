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
  final _focusNode = FocusNode();
  final _messageController = TextEditingController();
  _chatRoomViewState({Key key, this.chatRoomID, this.chatRoomName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chatRoomName),
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 75),
            child: chatRoomID == "chatInit"
                ? Text("Send the first message")
                : StreamBuilder(
                stream: db.collection('chatroom').document(chatRoomID).collection('messages').orderBy('date').snapshots(),
                builder: (context, snapshots){
                  if(!snapshots.hasData){
                    return LinearProgressIndicator();
                  }else{
                    return ListView.builder(
                        itemCount: snapshots.data.documents.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index){
                          return chatMessageItem(context, snapshots.data.documents[index]);
                        }
                    );
                  }
                }
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                focusNode: _focusNode,
                controller: _messageController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Send a message',
                  filled: true,
                  fillColor: Colors.grey,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send_rounded,),
                    onPressed: () {
                      setState(() {
                        _saveMessage();
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
  void _saveMessage() async{
    DateTime _now = DateTime.now();
    if(chatRoomID.startsWith("chatInit")){
      CollectionReference chatroomRef = db.collection('chatroom');
      String receiverID = chatRoomID.substring("chatInit".length+1);
      List<String> _particitants = new List<String>();
      _particitants.add(globals.dbUser.getUID());
      _particitants.add(receiverID);
      DocumentReference docRef = await chatroomRef.add({
        'lastDate': _now,
        'participants': _particitants,
      });
      CollectionReference msgsRef = docRef.collection('messages');
      await msgsRef.add({
        'content':_messageController.text,
        'date': _now,
        'sender': globals.dbUser.getUID()
      });
    }else{
      CollectionReference msgsRef = db.collection('chatroom').document(chatRoomID).collection('messages');
      await msgsRef.add({
        'content':_messageController.text,
        'date': _now,
        'sender': globals.dbUser.getUID()
      });
      DocumentReference chatroomRef = db.collection('chatroom').document(chatRoomID);
      await chatroomRef.updateData({
        'lastDate':_now,
      });
    }
    _focusNode.unfocus();
    _messageController.clear();
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