import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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

class _chatRoomViewState extends State<chatRoomView>
    with WidgetsBindingObserver {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String chatRoomID;
  String chatRoomName;
  String receiverID;
  final _focusNode = FocusNode();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  Stream chatStream;
  StreamSubscription chatStreamSub;
  _chatRoomViewState({Key key, this.chatRoomID, this.chatRoomName});
  int _unreadCount;
  int _unreadIndex;
  int _lastIndex;
  bool _shouldScroll = true;
  bool _shouldScrollToUnread = true;
  void ScrollToEnd() async {
      if(_shouldScrollToUnread){
        itemScrollController.scrollTo(index: _unreadIndex, duration: Duration(milliseconds: 500));
        _shouldScrollToUnread = false;
      }else{
        itemScrollController.jumpTo(index: _lastIndex+1);
      }
      _shouldScroll = false;
  }

  @override
  void initState() {
    super.initState();
    if (chatRoomID.startsWith("chatInit")) {
      getInitialChatInfo();
    } else {
      setStream(chatRoomID);
    }
  }
  Future getInitialChatInfo() async {
    //get receiverID
    receiverID = chatRoomID.substring("chatInit".length + 1);
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
          setState(() {
            setStream(chatRoomID);
          });
        }
      }
    }
    chatRoomName = await _getReceiverNick(receiverID);
    setState(() {});
  }
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
  Future setStream(String CRID) async {
    //get receiverID
    if(receiverID == null){
      await db
          .collection('chatroom')
          .document(chatRoomID)
          .get()
          .then((result) async {
        List<dynamic> participants = result.data['participants'];
        participants.removeWhere((element) => element == globals.dbUser.getUID());
        receiverID = participants[0];
      });
    }
    //add widget binding observer
    WidgetsBinding.instance.addObserver(this);
    //make user online
    await userOnLine(CRID);
    setState(() {
      //register stream and stream subscriber
      chatStream = db
          .collection('chatroom')
          .document(CRID)
          .collection('messages')
          .orderBy('date')
          .snapshots();
      chatStreamSub = chatStream.listen(null);
      chatStreamSub.onData((snapshot) {
        if (snapshot.documents[snapshot.documents.length - 1]["sender"] !=
            globals.dbUser.getUID()) {
          if(itemScrollController.isAttached){
            if (itemPositionsListener.itemPositions.value.last.index<_lastIndex) {
              String latestMessage =
              snapshot.documents[snapshot.documents.length - 1]["content"];
              scaffoldKey.currentState.showSnackBar(
                SnackBar(
                  content: Text(latestMessage),
                  action: SnackBarAction(
                    label: "보기",
                    onPressed: () => {
                      setState(() {
                        _shouldScroll = true;
                      })
                    },
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            } else {
              setState(() {
                _shouldScroll = true;
              });
            }
          }
        }
      });
    });
    setState(() {

    });
  }
  Future userOnLine(String CRID) async {
    //make user online
    DocumentReference docRef = db.collection('chatroom').document(CRID);
    db.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(docRef);
      final fresh = freshSnapshot.data;
      _unreadCount = fresh['unreadCount'][globals.dbUser.getUID()];
      List<dynamic> onlineUsers = fresh["onlineUser"];
      if (!onlineUsers.contains(globals.dbUser.getUID())) {
        onlineUsers.add(globals.dbUser.getUID());
      }
      await transaction.update(docRef, {
        'onlineUser': onlineUsers,
        'unreadCount.${globals.dbUser.getUID()}': 0,
      });
    });
    if(receiverID!=null){
      await db
          .collection('chatroom')
          .document(CRID)
          .collection('messages')
          .where('sender', isEqualTo: receiverID)
          .where('isRead', isEqualTo: false)
          .getDocuments()
          .then((value) => value.documents.forEach((element) {
        element.reference.updateData({'isRead': true});
      }));
    }
  }
  Future userOffLine(String CRID) async {
    DocumentReference docRef = db.collection('chatroom').document(CRID);
    db.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(docRef);
      final fresh = freshSnapshot.data;
      List<dynamic> onlineUsers = fresh["onlineUser"];
      onlineUsers.removeWhere((element) => element == globals.dbUser.getUID());
      await transaction.update(docRef, {'onlineUser': onlineUsers});
    });
  }

  @override
  void dispose() {
    if (!chatRoomID.startsWith("chatInit")) {
      userOffLine(chatRoomID);
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!chatRoomID.startsWith('chatInit')) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.detached) {
        print("app paused");
        userOffLine(chatRoomID);
      } else if (state == AppLifecycleState.resumed) {
        print("app resumed");
        userOnLine(chatRoomID);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: chatRoomName != null ? Text(chatRoomName) : Text("Error"),
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
                          print('data loading');
                          return LinearProgressIndicator();
                        } else {
                          if (_shouldScroll) {
                            _lastIndex = snapshots.data.documents.length-1;
                            _unreadIndex = _lastIndex;
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => ScrollToEnd());
                            _shouldScroll = false;
                          }
                          return ScrollablePositionedList.builder(
                              itemScrollController: itemScrollController,
                              itemPositionsListener: itemPositionsListener,
                              itemCount: snapshots.data.documents.length,
                              itemBuilder: (context, index) {
                                if(index == snapshots.data.documents.length-_unreadCount){
                                  _unreadIndex = index;
                                  return Column(
                                    children: [
                                      Container(
                                        width: 150,
                                        alignment: Alignment.center,
                                        child: Text("여기까지 읽었습니다"),
                                      ),
                                      chatMessageItem(
                                      context, snapshots.data.documents[index])
                                    ],
                                  );
                                }else{
                                  return chatMessageItem(
                                      context, snapshots.data.documents[index]);
                                }
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
        'onlineUser': [globals.dbUser.getUID()],
        'lastMessage': _messageController.text,
        'unreadCount':{
          receiverID : 1,
          globals.dbUser.getUID() : 0,
        }
      });
      CollectionReference msgsRef = docRef.collection('messages');
      await msgsRef.add({
        'content': _messageController.text,
        'date': _now,
        'sender': globals.dbUser.getUID(),
        'isRead': false,
      });
      setState(() {
        chatRoomID = docRef.documentID;
        setStream(chatRoomID);
      });
    } else {
      DocumentReference chatroomRef =
          db.collection('chatroom').document(chatRoomID);
      DocumentSnapshot docSnapshot = await chatroomRef.get();
      CollectionReference msgsRef = chatroomRef.collection('messages');
      bool isRead = docSnapshot['onlineUser'].length > 1;
      String new_message = _messageController.text;
      await msgsRef.add({
        'content': new_message,
        'date': _now,
        'sender': globals.dbUser.getUID(),
        'isRead': isRead
      });
      db.runTransaction((transaction) async {
        print("In Transaction: "+new_message);
        final freshSnapshot = await transaction.get(chatroomRef);
        final fresh = freshSnapshot.data;
        List<dynamic> onlineUsers = fresh["onlineUser"];
        if (onlineUsers.contains(receiverID)) {
          await transaction.update(chatroomRef, {
            'lastDate': _now,
            'lastMessage': new_message,
          });
        }else{
          await transaction.update(chatroomRef, {
            'lastDate': _now,
            'lastMessage': new_message,
            'unreadCount.$receiverID': fresh['unreadCount'][receiverID]+1,
          });
        }
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
