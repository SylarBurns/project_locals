import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
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
  final String commentID;

  PostView({
    Key key,
    @required this.postDocID,
    @required this.boardName,
    @required this.boardType,
    @required this.writerUID,
    this.commentID,
  }) : super(key: key);

  _PostViewState createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  bool _isDataLoaded = false;

  DocumentReference postDocRef;
  DocumentSnapshot postDocSnapshot;
  StorageReference storageRef;
  var imageURL;

  DocumentReference commentDocRef;
  CollectionReference commentListRef;
  QuerySnapshot commentListQuery;

  Map<String, CollectionReference> nestedCommentRef = Map<String, CollectionReference>();
  Map<String, QuerySnapshot> nestedCommentQuery = Map<String, QuerySnapshot>();

  FutureOr _refresh(dynamic value) {
    setState(() {});
  }

  refresh() {
    setState(() {});
  }

  void loadData() async {
    postDocRef = db.collection('board').document(widget.postDocID);
    postDocSnapshot = await postDocRef.get();
    String temp = postDocSnapshot['image'];
    if(temp != null) {
      storageRef = FirebaseStorage.instance.ref().child('post/$temp');
      imageURL = await storageRef.getDownloadURL();
    }

    commentDocRef = db.collection('comments').document(widget.postDocID);
    commentListRef = commentDocRef.collection('commentList');
    await commentListRef.orderBy('date').getDocuments().then((value) async {
       commentListQuery = value;
    });

    int len = commentListQuery.documents.length;
    for(int i=0; i<len; ++i) {
      DocumentSnapshot comment = commentListQuery.documents[i];
      if(comment['nestedComments'] != 0) {
        String docID = comment.documentID;
        CollectionReference ref = comment.reference.collection('nestedComment');
        await ref.orderBy('date').getDocuments().then((value) {
          QuerySnapshot query = value;

          nestedCommentRef[docID] = ref;
          nestedCommentQuery[docID] = query;
        });
      }
    }

    _isDataLoaded = true;
    refresh();
  }

  @override
  void initState() {
    super.initState();

    loadData();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.boardName}',
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
              switch(selectedMenu) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostEdit(post: postDocSnapshot,),
                    ),
                  ).then(_refresh);
                  break;
                case 'remove':
                  await postDocRef.delete();
                  commentDocRef.delete();

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
                  List reportUserList = postDocSnapshot['reportUserList'];

                  if(reportUserList.contains(globals.dbUser.getUID())) {
                    _showDialog('이미 신고한 게시글입니다.');
                  }
                  else {
                    await postDocRef.updateData({
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
      ),
      body: Padding(
        padding: globals.dbUser.getAuthority()
            ? EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 9)
            : EdgeInsets.zero,
        child: _isDataLoaded ? ListView(
          children: [
            _buildPost(context, postDocSnapshot),
            Column(
              children: commentListQuery.documents.map((comment) {
                return Column(
                  children: [
                    CommentTile(
                      postDocID: widget.postDocID,
                      comment: comment,
                      postWriter: widget.writerUID,
                      refresh: refresh,
                      showDialog: _showDialog,
                      loadData: loadData,
                      boardType: widget.boardType,
                    ),
                    if(comment['nestedComments'] != 0)...[
                      Column(
                        children: nestedCommentQuery[comment.documentID].documents.map((nestedComment) {
                          return  NestedCommentTile(
                            postDocID: widget.postDocID,
                            nestedComment: nestedComment,
                            postWriter: widget.writerUID,
                            commentRef: comment.reference,
                            refresh: refresh,
                            showDialog: _showDialog,
                            loadData: loadData,
                            boardType: widget.boardType,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              }).toList(),
            ),
          ],
        ) : Center(
          child: globals.getLoadingAnimation(context),
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
          fillColor: Theme.of(context).backgroundColor,
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
              loadData();
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
    DocumentReference docRef = db.collection('board').document(widget.postDocID);
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

      if(userUID != widget.writerUID) {
        DocumentSnapshot snap = await docRef.get();
        DocumentReference ref = db.collection('user').document(widget.writerUID);
        ref.updateData({
          'unreadNotification': FieldValue.increment(1),
          'unreadCount': FieldValue.increment(1),
        });

        await ref.collection('notification').add({
          'boardType': widget.boardType,
          'date': DateTime.now(),
          'writerNick': writerNick,
          'comment': commentController.text,
          'content': snap['title'],
          'type': 'comment',
          'isRead': false,
          'postDocID': widget.postDocID,
        });
      }
    }
    else {
      await colRef.document(commentDocID).collection('nestedComment').add(data);
      await colRef.document(commentDocID).updateData({
        'nestedComments': FieldValue.increment(1),
      });
      commentDocID = 'null';

      if(userUID != widget.writerUID) {
        DocumentSnapshot snap = await colRef.document(commentDocID).get();
        DocumentReference ref = db.collection('user').document(widget.writerUID);
        ref.updateData({
          'unreadNotification': FieldValue.increment(1),
          'unreadCount': FieldValue.increment(1),
        });

        await ref.collection('notification').add({
          'boardType': widget.boardType,
          'date': DateTime.now(),
          'writerNick': writerNick,
          'comment': commentController.text,
          'content': snap['content'],
          'type': 'nestedComment',
          'isRead': false,
          'postDocID': widget.postDocID,
        });
      }
    }

    await docRef.updateData({
      'comments': FieldValue.increment(1),
    });
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
    String image = post['image'];

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
                      color: Theme.of(context).accentColor.withOpacity(0.45),
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
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 3.0,),
                    Text(
                      'Like',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
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
                          'unreadCount': FieldValue.increment(1),
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
                          'content': title,
                        });
                      }
                    }
                    loadData();
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
          if(image != null)...[
            Container(
              padding: EdgeInsets.fromLTRB(5, 3, 5, 3),
              alignment: Alignment.center,
              // decoration: BoxDecoration(
              //   borderRadius: BorderRadius.circular(20),
              //   border: Border.all(color: Colors.black12),
              // ),
              child: Image.network(
                imageURL,
                height: MediaQuery.of(context).size.height/4,
              ),
            ),
            SizedBox(height: 5.0,)
          ],
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
                color: Theme.of(context).accentColor.withOpacity(0.45),
              ),
              Padding(padding: EdgeInsets.only(right: 2.0)),
              Text(
                '$like',
                style: TextStyle(color: Theme.of(context).accentColor.withOpacity(0.45),),
              ),
              Padding(padding: EdgeInsets.only(right: 10.0)),
              Icon(
                Icons.comment_bank_outlined,
                size: 15.0,
                color: Theme.of(context).accentColor.withOpacity(0.45),
              ),
              Padding(padding: EdgeInsets.only(right: 2.0)),
              Text(
                  '$comments',
                  style: TextStyle(color: Theme.of(context).accentColor.withOpacity(0.45),),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatefulWidget {
  final String postDocID;
  final DocumentSnapshot comment;
  final String postWriter;
  final Function refresh;
  final Function showDialog;
  final Function loadData;
  final String boardType;
  CommentTile({
    Key key,
    this.postDocID,
    this.comment,
    this.postWriter,
    this.refresh,
    this.showDialog,
    this.loadData,
    this.boardType,
  }) : super(key: key);

  CommentTileState createState() => CommentTileState();
}

class CommentTileState extends State<CommentTile> {
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
                        color: Theme.of(context).accentColor.withOpacity(0.38),
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
                        child: Text('OK', style: Theme.of(context).textTheme.button),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                      FlatButton(
                        child: Text('Cancel', style: Theme.of(context).textTheme.button),
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
                          color: Theme.of(context).accentColor.withOpacity(0.38),
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
                            color: writerUID == widget.postWriter ? Colors.lightBlue : Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 2.0,),
                        Row(
                          children: [
                            Text(
                              '$date',
                              style: TextStyle(
                                color: Theme.of(context).accentColor.withOpacity(0.45),
                              ),
                            ),
                            SizedBox(width: 5.0,),
                            if (like != 0)
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up_off_alt,
                                    size: 16.0,
                                    color: Theme.of(context).accentColor.withOpacity(0.45),
                                  ),
                                  SizedBox(width: 2.0,),
                                  Text(
                                    '$like',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Theme.of(context).accentColor.withOpacity(0.45),
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
                          color: Theme.of(context).accentColor.withOpacity(0.26),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.comment,
                              size: 20,
                              color: Theme.of(context).primaryColor,
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
                                        child: Text('OK', style: Theme.of(context).textTheme.button),
                                        onPressed: () {
                                          commentDocID = widget.comment.documentID;
                                          Navigator.pop(context, true);
                                        },
                                      ),
                                      FlatButton(
                                        child: Text('Cancel', style: Theme.of(context).textTheme.button),
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
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () async {
                              DocumentReference docRef = db.collection('user').document(globals.dbUser.getUID());
                              DocumentSnapshot doc = await docRef.get();
                              List tags = doc.data['commentLikeList'];

                              if(tags.contains(widget.comment.documentID)) {
                                widget.showDialog('이미 좋아요를 눌렀습니다.');
                              }
                              else {
                                // _isDataLoaded = false;
                                widget.showDialog('성공적으로 좋아요를 눌렀습니다.');
                                await docRef.updateData({
                                  'commentLikeList': FieldValue.arrayUnion([widget.comment.documentID]),
                                });
                                await widget.comment.reference.updateData({
                                  'like': FieldValue.increment(1),
                                });

                                if(globals.dbUser.getUID() != writerUID) {
                                  DocumentReference ref = db.collection('user').document(writerUID);
                                  ref.updateData({
                                    'unreadNotification': FieldValue.increment(1),
                                    'unreadCount': FieldValue.increment(1),
                                  });

                                  String nick;
                                  if(widget.boardType == 'anonymous') nick = 'Anonymous';
                                  else nick = globals.dbUser.getNickName();

                                  ref.collection('notification').add({
                                    'type': 'like',
                                    'boardType': widget.boardType,
                                    'writerNick': nick,
                                    'date': DateTime.now(),
                                    'isRead': false,
                                    'postDocID': widget.postDocID,
                                    'content': '$content',
                                  });
                                }
                                widget.loadData();
                                // widget.refresh();
                              }
                            },
                          ),
                          IconTheme(
                            data: IconThemeData(color: Theme.of(context).primaryColor),
                            child: PopupMenuButton(
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
  final Function loadData;
  final String boardType;

  NestedCommentTile({
    Key key,
    this.postDocID,
    this.postWriter,
    this.nestedComment,
    this.commentRef,
    this.refresh,
    this.showDialog,
    this.loadData,
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
                          child: Text('OK', style: Theme.of(context).textTheme.button),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        ),
                        FlatButton(
                          child: Text('Cancel', style: Theme.of(context).textTheme.button),
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
                  color: Theme.of(context).accentColor.withOpacity(0.12),
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
                            color: Theme.of(context).accentColor.withOpacity(0.38),
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
                color: Theme.of(context).accentColor.withOpacity(0.12),
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
                              color: writerUID == widget.postWriter ? Colors.lightBlue : Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(height: 2.0,),
                          Row(
                            children: [
                              Text(
                                '$date',
                                style: TextStyle(
                                  color: Theme.of(context).accentColor.withOpacity(0.45),
                                ),
                              ),
                              SizedBox(width: 5.0,),
                              like != 0 ?
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up_off_alt,
                                    size: 16.0,
                                    color: Theme.of(context).accentColor.withOpacity(0.45),
                                  ),
                                  SizedBox(width: 2.0,),
                                  Text(
                                    '$like',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Theme.of(context).accentColor.withOpacity(0.45),
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
                            color: Theme.of(context).accentColor.withOpacity(0.26),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.thumb_up_off_alt,
                                size: 20,
                                color: Theme.of(context).primaryColor
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

                                  if(globals.dbUser.getUID() != writerUID) {
                                    DocumentReference ref = db.collection('user').document(writerUID);
                                    ref.updateData({
                                      'unreadNotification': FieldValue.increment(1),
                                      'unreadCount': FieldValue.increment(1),
                                    });

                                    String nick;
                                    if(widget.boardType == 'anonymous') nick = 'Anonymous';
                                    else nick = globals.dbUser.getNickName();

                                    ref.collection('notification').add({
                                      'type': 'like',
                                      'boardType': widget.boardType,
                                      'writerNick': nick,
                                      'date': DateTime.now(),
                                      'isRead': false,
                                      'postDocID': widget.postDocID,
                                      'content': '$content',
                                    });
                                  }
                                  widget.loadData();
                                  // widget.refresh();
                                }
                              },
                            ),
                            IconTheme(
                              data: IconThemeData(color: Theme.of(context).primaryColor),
                              child: PopupMenuButton(
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