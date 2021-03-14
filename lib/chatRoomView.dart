import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;

final db = Firestore.instance;

class chatRoomView extends StatefulWidget {
  final String chatRoomID;
  final String chatRoomName;
  chatRoomView(
      {Key key, @required this.chatRoomID, @required this.chatRoomName});
  @override
  _chatRoomViewState createState() => _chatRoomViewState(
      chatRoomID: this.chatRoomID, chatRoomName: this.chatRoomName);
}

class _chatRoomViewState extends State<chatRoomView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String chatRoomID;
  String chatRoomName;
  final _focusNode = FocusNode();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream chatStream;
  StreamSubscription chatStreamSub;
  _chatRoomViewState({Key key, this.chatRoomID, this.chatRoomName});
  Future _getReceiverNick(String receiverID) async {
    String result = "";
    DocumentSnapshot ds =
        await db.collection('user').document(receiverID).get();
    if (ds.data.isNotEmpty) {
      result = ds["nickName"];
    } else {
      result = "Requested user is not on our database!";
    }
    return result;
  }
  Future getInitialChatInfo() async {
    String receiverID = chatRoomID.substring("chatInit".length + 1);
    String senderID = globals.dbUser.getUID();
    QuerySnapshot docSnapshots = await db
        .collection('chatroom')
        .where('participants', arrayContains: senderID)
        .getDocuments();
    if (docSnapshots.documents.isNotEmpty) {
      for (int docIndex = 0;
          docIndex < docSnapshots.documents.length;
          docIndex++) {
        if (docSnapshots.documents[docIndex]['participants'].length == 2 &&
            docSnapshots.documents[docIndex]['participants']
                .contains(receiverID)) {
          print("already exists");
          chatRoomID = docSnapshots.documents[docIndex].documentID;
        }
      }
    }
    chatRoomName = await _getReceiverNick(receiverID);
    setState(() {});
  }
  bool _shouldScroll = true;
  void ScrollToEnd() async {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent+50);
  }
  void setStream(String CRID) async{
    chatStream = db
        .collection('chatroom')
        .document(CRID)
        .collection('messages')
        .orderBy('date')
        .snapshots();
    chatStreamSub = chatStream.listen(null);
    chatStreamSub.onData((snapshot) {
      if(snapshot.documents[snapshot.documents.length-1]["sender"]!=globals.dbUser.getUID()){
        if(_scrollController.offset < _scrollController.position.maxScrollExtent-50){
          String latestMessage = snapshot.documents[snapshot.documents.length-1]["content"];
          scaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(latestMessage),
              action: SnackBarAction(
                label: "보기",
                onPressed: ()=>{
                  setState(() {
                    _shouldScroll = true;
                  })
                },
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }else{
          setState(() {
            _shouldScroll = true;
          });
        }
      }
    });
  }
  @override
  void initState() {
    if (chatRoomID.startsWith("chatInit")) {
      getInitialChatInfo();
    }else{
      setStream(chatRoomID);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: chatRoomName!=null ? Text(chatRoomName) : Text("Error"),
        ),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 75),
              child: chatRoomID.startsWith("chatInit")
                  ? Center(
                      child: Text("Send the first message"),
                    )
                  : StreamBuilder(
                      stream: chatStream,
                      builder: (context, snapshots) {
                        if (!snapshots.hasData) {
                          return LinearProgressIndicator();
                        } else {
                          if(_shouldScroll){
                            WidgetsBinding.instance.addPostFrameCallback((_)=>ScrollToEnd());
                            _shouldScroll=false;
                          }
                          return ListView.builder(
                              controller: _scrollController,
                              itemCount: snapshots.data.documents.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return chatMessageItem(
                                    context, snapshots.data.documents[index]);
                              });
                        }
                      }),
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
                      icon: Icon(
                        Icons.send_rounded,
                      ),
                      onPressed: () {
                        setState(() {
                          _shouldScroll = true;
                          _saveMessage();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  void _saveMessage() async {
    DateTime _now = DateTime.now();
    if (chatRoomID.startsWith("chatInit")) {
      CollectionReference chatroomRef = db.collection('chatroom');
      String receiverID = chatRoomID.substring("chatInit".length + 1);
      List<String> _particitants = new List<String>();
      _particitants.add(globals.dbUser.getUID());
      _particitants.add(receiverID);
      DocumentReference docRef = await chatroomRef.add({
        'lastDate': _now,
        'participants': _particitants,
      });
      CollectionReference msgsRef = docRef.collection('messages');
      await msgsRef.add({
        'content': _messageController.text,
        'date': _now,
        'sender': globals.dbUser.getUID()
      });
      setState(() {
        chatRoomID = docRef.documentID;
        setStream(chatRoomID);
      });
    } else {
      CollectionReference msgsRef =
          db.collection('chatroom').document(chatRoomID).collection('messages');
      await msgsRef.add({
        'content': _messageController.text,
        'date': _now,
        'sender': globals.dbUser.getUID()
      });
      DocumentReference chatroomRef =
          db.collection('chatroom').document(chatRoomID);
      await chatroomRef.updateData({
        'lastDate': _now,
      });
    }
    //_focusNode.unfocus();
    _messageController.clear();
  }

  Widget chatMessageItem(BuildContext context, DocumentSnapshot document) {
    bool isSender = document['sender'] == globals.dbUser.getUID();
    Timestamp tt = document["date"];
    DateTime dateTime =
        DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = "";
    if (DateTime.now().difference(dateTime) <= new Duration(hours: 24)) {
      date = DateFormat.Hm().format(dateTime);
    } else {
      date = DateFormat.Md().add_Hm().format(dateTime);
    }
    return Container(
      padding: EdgeInsets.all(8),
      child: FractionallySizedBox(
          child: isSender
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                    messagebody(document["content"], isSender)
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    messagebody(document["content"], isSender),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                  ],
                )),
    );
  }

  Widget messagebody(String content, bool isSender) {
    return Flexible(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            content,
            style: TextStyle(fontSize: 20),
          ),
        ),
        color: isSender ? Colors.lightBlue : Colors.white,
      ),
    );
  }
}
