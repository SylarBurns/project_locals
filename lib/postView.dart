import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'globals.dart' as globals;

import 'chatRoomView.dart';
import 'postEdit.dart';

final db = Firestore.instance;
final focusNode = FocusNode();
final commentController = TextEditingController();
String commentDocID = 'null';

class PostView extends StatefulWidget {
  final String postDocID;
  final String boardName;
  final String boardType;
  final String writerUID;

  PostView({
    Key key,
    @required this.postDocID,
    @required this.boardName,
    @required this.boardType,
    @required this.writerUID,
  }) : super(key: key);

  _PostViewState createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {

  FutureOr _refresh(dynamic value) {
    setState(() {});
  }

  refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          '${widget.boardName}',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) =>
            widget.writerUID == globals.dbUser.getUID()
                ? [
              PopupMenuItem(
                child: Text('수정하기'),
                value: 'edit',
              ),
              PopupMenuItem(
                child: Text('삭제하기'),
                value: 'remove',
              ),
            ]
                : [
              PopupMenuItem(
                child: Text('쪽지 보내기'),
                value: 'message',
              ),
              PopupMenuItem(
                child: Text('신고하기'),
                value: 'report',
              ),
            ],
            onSelected: (selectedMenu) async {
              DocumentReference docRef = db.collection('board').document(widget.postDocID);
              DocumentSnapshot post = await docRef.get();

              switch(selectedMenu) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostEdit(post: post,),
                    ),
                  ).then(_refresh);
                  break;
                case 'remove':
                  await docRef.delete();
                  await db.collection('comments').document(widget.postDocID).delete();

                  Navigator.pop(context);
                  break;
                case 'message':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context){
                         String chatRoomID = "chatInit/${widget.writerUID}/${widget.boardType}";
                         return chatRoomView(
                           chatRoomID: chatRoomID,
                           chatRoomName: "new message",
                         );
                        }
                      )
                  );
                  break;
                case 'report':
                  List reportUserList = post['reportUserList'];

                  if(reportUserList.contains(globals.dbUser.getUID())) {
                    _showDialog('이미 신고한 게시글입니다.');
                  }
                  else {
                    await docRef.updateData({
                      'report': FieldValue.increment(1),
                      'reportUserList': FieldValue.arrayUnion([globals.dbUser.getUID()]),
                    });
                    _showDialog('신고가 접수 되었습니다.');
                  }
                  break;
                default :
                  break;
              }
            },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 9),
        child: ListView(
          children: [
            FutureBuilder(
              future: db.collection('board').document(widget.postDocID).get(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData == false) {
                  return Container();
                }
                else {
                  return _buildPost(context, snapshot.data);
                }
              },
            ),
            FutureBuilder(
              future: db.collection('comments').document(widget.postDocID).collection('commentList').orderBy('date').getDocuments(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                else {
                  return Column(
                    children: snapshot.data.documents.map((comment) {
                      return Column(
                        children: [
                          CommentTileTemp(
                            postDocID: widget.postDocID,
                            comment: comment,
                            postWriter: widget.writerUID,
                            refresh: refresh,
                            showDialog: _showDialog,
                            boardType: widget.boardType,
                          ),
                          FutureBuilder(
                            future: comment.reference.collection('nestedComment').orderBy('date').getDocuments(),
                            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> nsSnapshot) {
                              if(!nsSnapshot.hasData) {
                                return Container();
                              }
                              else {
                                return Column(
                                  children: nsSnapshot.data.documents.map((nestedComment) {
                                    return  NestedCommentTile(
                                      postDocID: widget.postDocID,
                                      nestedComment: nestedComment,
                                      postWriter: widget.writerUID,
                                      commentRef: comment.reference,
                                      refresh: refresh,
                                      showDialog: _showDialog,
                                      boardType: widget.boardType,
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomSheet: _bottomTextField(context),
    );
  }

  Widget _bottomTextField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextField(
        controller: commentController,
        focusNode: focusNode,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Write a comment',
          filled: true,
          fillColor: Colors.black12,
          suffixIcon: IconButton(
            icon: Icon(Icons.send_rounded,),
            onPressed: () async {
              if(commentController.text.length > 0) {
                await _saveComment();
                focusNode.unfocus();
                commentController.clear();
              }
              else {
                _showDialog('텍스트를 입력하세요.');
              }
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  Future _saveComment() async {
    CollectionReference colRef = db.collection('comments').document(widget.postDocID).collection('commentList');
    String userUID = globals.dbUser.getUID();
    String writerNick = globals.dbUser.getNickName();

    var data = {
      'content': commentController.text,
      'date': DateTime.now(),
      'like': 0,
      'writer': userUID,
      'writerNick': writerNick,
      'report': 0,
      'reportUserList': [],
    };

    if(widget.boardType == 'anonymous') {
      writerNick = 'Anonymous';
      DocumentReference docRef = db.collection('board').document(widget.postDocID);
      await db.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(docRef);
        final anonymousList = freshSnapshot.data['anonymousList'];
        if (anonymousList.containsKey(userUID)) {
          data['writerNick'] = anonymousList[userUID];
        }
        else {
          int num = anonymousList.length;
          data['writerNick'] = 'Anonymous' + num.toString();
          await transaction.update(docRef, {
            'anonymousList.$userUID': 'Anonymous' + num.toString(),
          });
        }
      });
    }

    if(commentDocID == 'null') {
      data['isDelete'] = false;
      data['nestedComments'] = 0;
      await colRef.add(data);
    }
    else {
      await colRef.document(commentDocID).collection('nestedComment').add(data);
      await colRef.document(commentDocID).updateData({
        'nestedComments': FieldValue.increment(1),
      });
      commentDocID = 'null';
    }

    await db.collection('board').document(widget.postDocID).updateData({
      'comments': FieldValue.increment(1),
    });

    if(userUID != widget.writerUID) {
      DocumentReference ref = db.collection('user').document(widget.writerUID);
      ref.updateData({
        'unreadNotification': FieldValue.increment(1),
      });

      await ref.collection('notification').add({
        'boardType': widget.boardType,
        'date': DateTime.now(),
        'writerNick': writerNick,
        'content': commentController.text,
        'type': 'comment',
        'isRead': false,
        'postDocID': widget.postDocID,
      });
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0)
          ),

          content: SizedBox(
            width: 50,
            height: 30,
            child: Center(
              child: Text(
                  '$message'
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPost(BuildContext context, DocumentSnapshot post) {
    String title = post['title'];
    String content = post['content'];
    String writer = post['writerNick'];
    int like = post['like'];
    int comments = post['comments'];
    Timestamp tt = post['date'];
    String boardType = post['boardType'];

    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);

    return Container(
      padding: EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.person,
              ),
              SizedBox(width: 4.0,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$writer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                  SizedBox(height: 2.0,),
                  Text(
                    '$date',
                    style: TextStyle(
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              Spacer(),
              FlatButton(
                // color: Colors.white,
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_alt_outlined,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 3.0,),
                    Text(
                      'Like',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                onPressed: () async {
                  DocumentReference docRef = db.collection('user').document(globals.dbUser.getUID());
                  DocumentSnapshot doc = await docRef.get();
                  setState(() {
                    List tags = doc.data['postLikeList'];

                    if(tags.contains(post.documentID)) {
                      _showDialog('이미 좋아요를 눌렀습니다.');
                    }
                    else {
                      _showDialog('성공적으로 좋아요를 눌렀습니다.');
                      docRef.updateData({
                        'postLikeList': FieldValue.arrayUnion([post.documentID]),
                      });
                      post.reference.updateData({
                        'like': FieldValue.increment(1),
                      });

                      if(globals.dbUser.getUID() != widget.writerUID) {
                        DocumentReference ref = db.collection('user').document(widget.writerUID);
                        ref.updateData({
                          'unreadNotification': FieldValue.increment(1),
                        });

                        String writerNick;
                        if(widget.boardType == 'anonymous') writerNick = 'Anonymous';
                        else writerNick = globals.dbUser.getNickName();

                        ref.collection('notification').add({
                          'type': 'like',
                          'boardType': widget.boardType,
                          'writerNick': writerNick,
                          'date': DateTime.now(),
                          'isRead': false,
                          'postDocID': widget.postDocID,
                        });
                      }
                    }
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Text(
            '$title',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5.0,),
          Text(
            '$content',
          ),
          SizedBox(height: 8.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 15.0,
              ),
              Padding(padding: EdgeInsets.only(right: 2.0)),
              Text(
                '$like',
              ),
              Padding(padding: EdgeInsets.only(right: 10.0)),
              Icon(
                Icons.comment_bank_outlined,
                size: 15.0,
              ),
              Padding(padding: EdgeInsets.only(right: 2.0)),
              Text(
                  '$comments'
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentTileTemp extends StatefulWidget {
  final String postDocID;
  final DocumentSnapshot comment;
  final String postWriter;
  final Function refresh;
  final Function showDialog;
  final String boardType;
  CommentTileTemp({
    Key key,
    this.postDocID,
    this.comment,
    this.postWriter,
    this.refresh,
    this.showDialog,
    this.boardType,
  }) : super(key: key);

  CommentTileTempState createState() => CommentTileTempState();
}

class CommentTileTempState extends State<CommentTileTemp> {

  bool _isBlind = false;
  bool _onClicked = false;

  @override
  Widget build(BuildContext context) {
    int report = widget.comment['report'];
    int nestedComments = widget.comment['nestedComments'];
    bool isDelete = widget.comment['isDelete'];

    if(report >= 10 && !_onClicked) _isBlind = true;

    if (isDelete && nestedComments == 0)
      return Container();
    else if (isDelete) {
      return Column(
        children: [
          Divider(),
          Container(
            padding: EdgeInsets.fromLTRB(20.0, 1.0, 20.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.person,
                    ),
                    SizedBox(width: 4.0,),
                    Text(
                      '(삭제됨)',
                      style: TextStyle(
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0,),
                Text(
                  '삭제된 댓글입니다.',
                ),
              ],
            ),
          ),
        ],
      );
    }
    else if (_isBlind) {
      return Column(
        children: [
          Divider(),
          GestureDetector(
            onTap: () async {
              bool result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)
                    ),
                    content: Text('댓글 내용을 확인하시겠습니까?'),
                    actions: [
                      FlatButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                      FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                    ],
                  );
                },
              );
              if(result) {
                _isBlind = false;
                _onClicked = true;
                setState(() {});
              }
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(20.0, 1.0, 20.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.person,
                      ),
                      SizedBox(width: 4.0,),
                      Text(
                        '(Blind)',
                        style: TextStyle(
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.0,),
                  Text(
                      '블라인드 처리된 댓글입니다.'
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    else {
      String writer = widget.comment['writerNick'];
      String writerUID = widget.comment['writer'];
      String content = widget.comment['content'];
      int like = widget.comment['like'];
      Timestamp tt = widget.comment['date'];
      DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
      String date = DateFormat.Md().add_Hm().format(dateTime);

      return Column(
        children: [
          Divider(),
          Container(
            padding: EdgeInsets.fromLTRB(20.0, 1.0, 20.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.person,
                    ),
                    SizedBox(width: 4.0,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$writer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: writerUID == widget.postWriter ? Colors.lightBlue : Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.0,),
                        Row(
                          children: [
                            Text(
                              '$date',
                              style: TextStyle(
                                color: Colors.black45,
                              ),
                            ),
                            SizedBox(width: 5.0,),
                            if (like != 0)
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up_off_alt,
                                    size: 16.0,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 2.0,),
                                  Text(
                                    '$like',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        border: Border.all(
                          color: Colors.black26,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.comment,
                              size: 20,
                            ),
                            onPressed: () async {
                              bool result = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0)
                                    ),

                                    content: Text('대댓글을 작성하시겠습니까?'),
                                    actions: [
                                      FlatButton(
                                        child: Text('OK'),
                                        onPressed: () {
                                          commentDocID = widget.comment.documentID;
                                          Navigator.pop(context, true);
                                        },
                                      ),
                                      FlatButton(
                                        child: Text('Cancel'),
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              if(result) {
                                focusNode.requestFocus();
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up_off_alt,
                              size: 20,
                            ),
                            onPressed: () async {
                              DocumentReference docRef = db.collection('user').document(globals.dbUser.getUID());
                              DocumentSnapshot doc = await docRef.get();
                              List tags = doc.data['commentLikeList'];

                              if(tags.contains(widget.comment.documentID)) {
                                widget.showDialog('이미 좋아요를 눌렀습니다.');
                              }
                              else {
                                widget.showDialog('성공적으로 좋아요를 눌렀습니다.');
                                await docRef.updateData({
                                  'commentLikeList': FieldValue.arrayUnion([widget.comment.documentID]),
                                });
                                await widget.comment.reference.updateData({
                                  'like': FieldValue.increment(1),
                                });
                              }
                              widget.refresh();
                            },
                          ),
                          PopupMenuButton(
                            itemBuilder: (BuildContext context) =>
                            writerUID == globals.dbUser.getUID()
                                ? [
                              PopupMenuItem(
                                child: Text('삭제하기'),
                                value: 'remove',
                              )
                            ]
                                : [
                              PopupMenuItem(
                                child: Text('쪽지 보내기'),
                                value: 'message',
                              ),
                              PopupMenuItem(
                                child: Text('신고하기'),
                                value: 'report',
                              ),
                            ],
                            onSelected: (selectedMenu) async {
                              switch(selectedMenu) {
                                case 'remove':
                                  await db.collection('board').document(widget.postDocID).updateData({
                                    'comments': FieldValue.increment(-1),
                                  });
                                  await widget.comment.reference.updateData({
                                    'isDelete': true,
                                  });
                                  // setState(() {});
                                  widget.showDialog('성공적으로 삭제되었습니다.');
                                  widget.refresh();
                                  break;
                                case 'message':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context)=>
                                            chatRoomView(
                                              chatRoomID: "chatInit/$writerUID/${widget.boardType}",
                                              chatRoomName: "new message",
                                            ),
                                      )
                                  );
                                  break;
                                case 'report':
                                  List reportUserList = widget.comment['reportUserList'];

                                  if(reportUserList.contains(globals.dbUser.getUID())) {
                                    widget.showDialog('이미 신고한 게시글입니다.');
                                  }
                                  else {
                                    await widget.comment.reference.updateData({
                                      'report': FieldValue.increment(1),
                                      'reportUserList': FieldValue.arrayUnion([globals.dbUser.getUID()]),
                                    });
                                    widget.showDialog('신고가 접수 되었습니다.');
                                  }
                                  setState(() {});
                                  break;
                                default :
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0,),
                Text(
                  '$content',
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

class NestedCommentTile extends StatefulWidget {
  final String postDocID;
  final String postWriter;
  final DocumentSnapshot nestedComment;
  final DocumentReference commentRef;
  final Function refresh;
  final Function showDialog;
  final String boardType;

  NestedCommentTile({
    Key key,
    this.postDocID,
    this.postWriter,
    this.nestedComment,
    this.commentRef,
    this.refresh,
    this.showDialog,
    this.boardType,
  }) : super(key: key);

  NestedCommentTileState createState() => NestedCommentTileState();
}

class NestedCommentTileState extends State<NestedCommentTile> {

  bool _isBlind = false;
  bool _onClicked = false;

  @override
  Widget build(BuildContext context) {
    int report = widget.nestedComment['report'];
    if(report >= 10 && !_onClicked) _isBlind = true;

    if(_isBlind) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.0, 5.0, 5.0, 5.0),
            child: Icon(
              Icons.subdirectory_arrow_right,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                bool result = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)
                      ),
                      content: Text('댓글 내용을 확인하시겠습니까?'),
                      actions: [
                        FlatButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        ),
                        FlatButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                        ),
                      ],
                    );
                  },
                );
                if(result) {
                  _isBlind = false;
                  _onClicked = true;
                  setState(() {});
                }
              },
              child: Container(
                padding: EdgeInsets.all(10.0),
                margin: EdgeInsets.fromLTRB(0.0, 4.0, 8.0, 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.black12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person,
                        ),
                        SizedBox(width: 4.0,),
                        Text(
                          '(Blind)',
                          style: TextStyle(
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.0,),
                    Text(
                        '블라인드 처리된 댓글입니다.'
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    else {
      String content = widget.nestedComment['content'];
      String writer = widget.nestedComment['writerNick'];
      int like = widget.nestedComment['like'];
      Timestamp tt = widget.nestedComment['date'];
      String writerUID = widget.nestedComment['writer'];
      DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
      String date = DateFormat.Md().add_Hm().format(dateTime);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.0, 5.0, 5.0, 5.0),
            child: Icon(
              Icons.subdirectory_arrow_right,
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10.0),
              margin: EdgeInsets.fromLTRB(0.0, 4.0, 8.0, 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.black12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.person,
                      ),
                      SizedBox(width: 4.0,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$writer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: writerUID == widget.postWriter ? Colors.lightBlue : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.0,),
                          Row(
                            children: [
                              Text(
                                '$date',
                                style: TextStyle(
                                  color: Colors.black45,
                                ),
                              ),
                              SizedBox(width: 5.0,),
                              like != 0 ?
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up_off_alt,
                                    size: 16.0,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 2.0,),
                                  Text(
                                    '$like',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ) :
                              Container(),
                            ],
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          border: Border.all(
                            color: Colors.black26,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.thumb_up_off_alt,
                                size: 20,
                              ),
                              onPressed: () async {
                                DocumentReference docRef = db.collection('user').document(globals.dbUser.getUID());
                                DocumentSnapshot doc = await docRef.get();
                                List tags = doc.data['commentLikeList'];

                                if(tags.contains(widget.nestedComment.documentID)) {
                                  widget.showDialog('이미 좋아요를 눌렀습니다.');
                                }
                                else {
                                  widget.showDialog('성공적으로 좋아요를 눌렀습니다.');
                                  await docRef.updateData({
                                    'commentLikeList': FieldValue.arrayUnion(
                                        [widget.nestedComment.documentID]),
                                  });
                                  await widget.nestedComment.reference.updateData({
                                    'like': FieldValue.increment(1),
                                  });
                                  widget.refresh();
                                }
                              },
                            ),
                            PopupMenuButton(
                              itemBuilder: (BuildContext context) =>
                              writerUID == globals.dbUser.getUID()
                                  ? [
                                PopupMenuItem(
                                  child: Text('삭제하기'),
                                  value: 'remove',
                                )
                              ]
                                  : [
                                PopupMenuItem(
                                  child: Text('쪽지 보내기'),
                                  value: 'message',
                                ),
                                PopupMenuItem(
                                  child: Text('신고하기'),
                                  value: 'report',
                                ),
                              ],
                              onSelected: (selectedMenu) async {
                                switch(selectedMenu) {
                                  case 'remove':
                                    widget.nestedComment.reference.delete();
                                    widget.commentRef.updateData({
                                      'nestedComments': FieldValue.increment(-1),
                                    });
                                    db.collection('board').document(widget.postDocID).updateData({
                                      'comments': FieldValue.increment(-1),
                                    });
                                    widget.showDialog('성공적으로 삭제되었습니다.');
                                    widget.refresh();
                                    break;
                                  case 'message':
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context)=>
                                              chatRoomView(
                                                chatRoomID: "chatInit/$writerUID/${widget.boardType}",
                                                chatRoomName: "new message",
                                              ),
                                        )
                                    );
                                    break;
                                  case 'report':
                                    List reportUserList = widget.nestedComment['reportUserList'];

                                    if(reportUserList.contains(globals.dbUser.getUID())) {
                                      widget.showDialog('이미 신고한 게시글입니다.');
                                    }
                                    else {
                                      await widget.nestedComment.reference.updateData({
                                        'report': FieldValue.increment(1),
                                        'reportUserList': FieldValue.arrayUnion([globals.dbUser.getUID()]),
                                      });
                                      widget.showDialog('신고가 접수 되었습니다.');
                                    }
                                    setState(() {});
                                    break;

                                  default :
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.0,),
                  Text(
                    '$content',
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}