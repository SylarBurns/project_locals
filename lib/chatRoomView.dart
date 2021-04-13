import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  _chatRoomViewState({Key key, this.chatRoomID, this.chatRoomName});

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String chatRoomID;
  String chatRoomName;
  String receiverID;
  List<String> tokens = List<String>();

  final _focusNode = FocusNode();
  final _messageController = TextEditingController();
  File imageFile;

  final ScrollController _scrollController = ScrollController();

  Stream chatStream;
  StreamSubscription chatStreamSub;

  int _unreadCount;
  bool _shouldScroll;

  void ScrollToEnd() async {
    if (_shouldScroll) {
      print("current"+_scrollController.position.pixels.toString());
      print("min"+_scrollController.position.minScrollExtent.toString());
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      _shouldScroll = false;
      if(_unreadCount!=0){
        _unreadCount+=1;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (chatRoomID.startsWith("chatInit")) {
      getInitialChatInfo();
    } else {
      setStream(chatRoomID);
    }
    _shouldScroll = false;
  }
  @override
  void dispose() {
    if (!chatRoomID.startsWith("chatInit")) {
      userOffLine(chatRoomID);
      WidgetsBinding.instance.removeObserver(this);
    }
    _focusNode.unfocus();
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
    _messageController.addListener(() {
      setState(() {});
    });
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
                    if (snapshots.connectionState ==
                        ConnectionState.waiting) {
                      return LinearProgressIndicator();
                    } else if (snapshots.hasData) {
                      if (_shouldScroll) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => ScrollToEnd());
                      }
                      return ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          itemCount: snapshots.data.documents.length,
                          itemBuilder: (context, index) {
                            if (_unreadCount>0 && index == _unreadCount) {
                              // _unreadIndex = index;
                              return Column(
                                children: [
                                  chatMessageItem(context,
                                      snapshots.data.documents[index]),
                                  Container(
                                    width: 150,
                                    alignment: Alignment.center,
                                    child: Text("여기까지 읽었습니다"),
                                  ),
                                ],
                              );
                            } else {
                              return chatMessageItem(
                                  context, snapshots.data.documents[index]);
                            }
                          });
                    } else {
                      return LinearProgressIndicator();
                    }
                  }),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: TextField(
                  style: TextStyle(fontSize: 15),
                  focusNode: _focusNode,
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).backgroundColor,
                      border: OutlineInputBorder(),
                      hintText: 'Send a message',
                      hintStyle: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .color
                              .withOpacity(0.30)),
                      suffixIcon: _messageController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            _saveMessage(false, _messageController.text);
                            _shouldScroll = true;
                          });
                        },
                      )
                          : IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: () {
                            _showChoiceDialog(context);
                          })),
                ),
              ),
            ),
          ],
        ));
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
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .accentTextTheme
                        .bodyText1
                        .color),
              ),
              messagebody(document["type"], document["content"], isSender,
                  context)
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              messagebody(document['type'], document["content"], isSender,
                  context),
              Text(
                date,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .accentTextTheme
                        .bodyText1
                        .color),
              ),
            ],
          )),
    );
  }

  Widget messagebody(
      String type, String content, bool isSender, BuildContext context) {
    return Flexible(
      child: type == 'image'
          ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.8,
            child: FullScreenWidget(
                child: Hero(
                    tag: content,
                    child: CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          color: Theme.of(context).backgroundColor,
                        ),
                        imageUrl: content,
                        fit: BoxFit.cover))),
          ))
          : Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            child: Text(
              content,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        color: isSender
            ? Theme.of(context).cardColor
            : Theme.of(context).textSelectionColor,
      ),
    );
  }

  Future getInitialChatInfo() async {
    tokens = chatRoomID.split('/');
    receiverID = tokens[1];
    if (tokens[2] == "anonymous") {
      chatRoomName = "익명";
    } else if (tokens.length == 3) {
      String senderID = globals.dbUser.getUID();
      QuerySnapshot docSnapshots = await db
          .collection('chatroom')
          .where('participants', arrayContains: senderID)
          .where('isAnonymous', isEqualTo: false)
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
            await setStream(chatRoomID);
            setState(() {});
          }
        }
      }
      chatRoomName = await _getReceiverNick(receiverID);
    } else {
      chatRoomName = "Error";
    }
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
    if (!chatRoomID.startsWith('chatInit')) {
      await db
          .collection('chatroom')
          .document(chatRoomID)
          .get()
          .then((result) async {
        List<dynamic> participants = result.data['participants'];
        participants
            .removeWhere((element) => element == globals.dbUser.getUID());
        receiverID = participants[0];
      });
    }
    //add widget binding observer
    WidgetsBinding.instance.addObserver(this);
    //make user online
    await userOnLine(CRID);
    //register stream and stream subscriber
    chatStream = db
        .collection('chatroom')
        .document(CRID)
        .collection('messages')
        .orderBy('date', descending: true)
        .snapshots();
    chatStreamSub = chatStream.listen(null);
    chatStreamSub.onData((snapshot) {
      print("On DATA");
      if (snapshot.documents[0]["sender"] !=
          globals.dbUser.getUID()) {
        if (_scrollController.hasClients) {
          if (_scrollController.position.pixels > 50) {
            if(_unreadCount!=0){
              _unreadCount += 1;
            }
            String latestMessage =
                snapshot.documents[0]["content"];
            scaffoldKey.currentState.showSnackBar(
              SnackBar(
                content: Text(latestMessage),
                action: SnackBarAction(
                  label: "보기",
                  onPressed: () => {
                    setState(() {
                      if(_unreadCount!=0){
                        _unreadCount += 1;
                      }
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

    setState(() {});
  }

  Future userOnLine(String CRID) async {
    //make user online
    DocumentReference docRef = db.collection('chatroom').document(CRID);
    await db.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(docRef);
      final fresh = freshSnapshot.data;
      print(fresh["lastMessage"]);
      _unreadCount = fresh["unreadCount"][globals.dbUser.getUID()];
      List<dynamic> onlineUsers = fresh["onlineUser"];
      if (!onlineUsers.contains(globals.dbUser.getUID())) {
        onlineUsers.add(globals.dbUser.getUID());
      }
      await transaction.update(docRef, {
        'onlineUser': onlineUsers,
        'unreadCount.${globals.dbUser.getUID()}': 0,
      });
    });
    if (receiverID != null) {
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
    await globals.dbUser.userOnDB.get().then((userSnapshot) {
      globals.dbUser.userOnDB
          .updateData({"unreadCount": FieldValue.increment(-_unreadCount)});
    });
  }

  Future userOffLine(String CRID) async {
    DocumentReference docRef = db.collection('chatroom').document(CRID);
    await db.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(docRef);
      final fresh = freshSnapshot.data;
      List<dynamic> onlineUsers = fresh["onlineUser"];
      onlineUsers.removeWhere((element) => element == globals.dbUser.getUID());
      await transaction.update(docRef, {'onlineUser': onlineUsers});
    });
  }

  Future _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Choose option",
              style: TextStyle(color: Theme.of(context).accentColor),
            ),
            content: SingleChildScrollView(
                child: ListBody(
              children: [
                Divider(
                  height: 1,
                  color: Theme.of(context).accentColor,
                ),
                ListTile(
                  onTap: () {
                    _openGallery(context);
                  },
                  title: Text("Gallery"),
                  leading: Icon(
                    Icons.account_box,
                    color: Theme.of(context).accentColor,
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).accentColor
                ),
                ListTile(
                  onTap: () {
                    _openCamera(context);
                  },
                  title: Text("Camera"),
                  leading: Icon(
                    Icons.camera,
                    color: Theme.of(context).accentColor,
                  ),
                ),
              ],
            )),
          );
        });
  }

  Future _showLoadedImage(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("선택된 사진"),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Container(
                    child: Image.file(imageFile),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () async {
                          Navigator.pop(context);
                          await uploadImageToFirebase(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future uploadImageToFirebase(BuildContext context) async {
    String fileName = basename(imageFile.path);
    StorageReference firebaseStorageRef =
    FirebaseStorage.instance.ref().child('chatroom/$fileName');
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    taskSnapshot.ref.getDownloadURL().then((value) {
      setState(() {
        _shouldScroll = true;
        _focusNode.unfocus();
        _saveMessage(true, value);
      });
    });
  }

  void _openGallery(BuildContext context) async {
    await ImagePicker()
        .getImage(
      source: ImageSource.gallery,
    )
        .then((value) {
      setState(() async {
        imageFile = File(value.path);
        await _showLoadedImage(context);
        Navigator.pop(context);
      });
    });
  }

  void _openCamera(BuildContext context) async {
    await ImagePicker()
        .getImage(
      source: ImageSource.camera,
    )
        .then((value) {
      setState(() async {
        imageFile = File(value.path);
        await _showLoadedImage(context);
        Navigator.pop(context);
      });
    });
  }

  void _saveMessage(bool isImage, String content) async {
    DateTime _now = DateTime.now();
    if (chatRoomID.startsWith("chatInit")) {
      CollectionReference chatroomRef = db.collection('chatroom');
      List<String> _particitants = new List<String>();
      _particitants.add(globals.dbUser.getUID());
      _particitants.add(receiverID);
      await chatroomRef.add({
        'isAnonymous': tokens[2] == 'anonymous',
        'lastDate': _now,
        'participants': _particitants,
        'onlineUser': [globals.dbUser.getUID()],
        'lastMessage': isImage ? '<Photo>' : content,
        'unreadCount': {
          receiverID: 1,
          globals.dbUser.getUID(): 0,
        }
      }).then((docRef) async {
        CollectionReference msgsRef = docRef.collection('messages');
        if (isImage) {
          await msgsRef.add({
            'type': 'image',
            'content': content,
            'date': _now,
            'sender': globals.dbUser.getUID(),
            'isRead': false,
          });
        } else {
          await msgsRef.add({
            'type': 'text',
            'content': content,
            'date': _now,
            'sender': globals.dbUser.getUID(),
            'isRead': false,
          });
        }
        chatRoomID = docRef.documentID;
      }).then((value) async {
        await setStream(chatRoomID);
        setState(() {});
      });
      db.collection('user').document(receiverID).updateData({"unreadCount": FieldValue.increment(1)});
    } else {
      DocumentReference chatroomRef =
          db.collection('chatroom').document(chatRoomID);
      DocumentSnapshot docSnapshot = await chatroomRef.get();
      CollectionReference msgsRef = chatroomRef.collection('messages');
      bool isRead = docSnapshot['onlineUser'].length > 1;
      if (isImage) {
        await msgsRef.add({
          'type': 'image',
          'content': content,
          'date': _now,
          'sender': globals.dbUser.getUID(),
          'isRead': isRead,
        });
      } else {
        await msgsRef.add({
          'type': 'text',
          'content': content,
          'date': _now,
          'sender': globals.dbUser.getUID(),
          'isRead': isRead,
        });
      }
      await db.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(chatroomRef);
        final fresh = freshSnapshot.data;
        List<dynamic> onlineUsers = fresh["onlineUser"];
        if (onlineUsers.contains(receiverID)) {
          await transaction.update(chatroomRef, {
            'lastDate': _now,
            'lastMessage': isImage ? '<Photo>' : content,
          });
        } else {
          await transaction.update(chatroomRef, {
            'lastDate': _now,
            'lastMessage': isImage ? '<Photo>' : content,
            'unreadCount.$receiverID': fresh['unreadCount'][receiverID] + 1,
          });
          db.collection('user').document(receiverID).updateData({"unreadCount": FieldValue.increment(1)});
        }
      });
    }
    //_focusNode.unfocus();
    _messageController.clear();
  }
}
