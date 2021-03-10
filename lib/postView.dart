import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'globals.dart' as globals;
import 'chatRoomView.dart';
class PostView extends StatefulWidget {
  final String postDocID;
  final String boardName;
  final String writerUID;

  PostView({Key key, @required this.postDocID, @required this.boardName, @required this.writerUID});

  _PostViewState createState() => _PostViewState(
    key: this.key,
    postDocID: this.postDocID,
    boardName: this.boardName,
    writerUID: this.writerUID,
  );
}

class _PostViewState extends State<PostView> {
  String postDocID;
  String boardName;
  String writerUID;

  _PostViewState({Key key, this.postDocID, this.boardName, this.writerUID});

  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  String _commentDocID = 'null';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          '$boardName',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) =>
            writerUID == globals.dbUser.getUID()
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
            onSelected: (selectedMenu) {
              switch(selectedMenu){
                case 'message':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context)=>
                            chatRoomView(
                              chatRoomID: "chatInit/"+writerUID,
                              chatRoomName: "new message",
                            ),
                      )
                  );
                  break;
                default :
                  break;
              }
              print(selectedMenu);
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
              future: Firestore.instance.collection('board').document(postDocID).get(),
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
              future: Firestore.instance.collection('comments').document(postDocID).collection('commentList').orderBy('date').getDocuments(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                else {
                  return Column(
                    children: snapshot.data.documents.map((comment) {
                      return Column(
                        children: [
                          Divider(),
                          _buildComment(context, comment, postDocID),
                          FutureBuilder(
                            future: comment.reference.collection('nestedComment').orderBy('date').getDocuments(),
                            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> nsSnapshot) {
                              if(!nsSnapshot.hasData) {
                                return Container();
                              }
                              else {
                                return Column(
                                  children: nsSnapshot.data.documents.map((nestedComment) {
                                    return Column(
                                      children: [
                                        _buildNestedComment(context, nestedComment),
                                      ],
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
      bottomSheet: Padding(
        padding: EdgeInsets.all(8.0),
        child: TextField(
          focusNode: _focusNode,
          controller: _commentController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Write a comment',
            filled: true,
            fillColor: Colors.black12,
            suffixIcon: IconButton(
              icon: Icon(Icons.send_rounded,),
              onPressed: () {
                setState(() {
                  _saveComment();
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPost(BuildContext context, DocumentSnapshot post) {
    String title = post['title'];
    String content = post['content'];
    String writer = post['writerNick'];
    int like = post['like'];
    int comments = post['comments'];
    Timestamp tt = post['date'];

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
                  DocumentReference docRef = Firestore.instance.collection('user').document(globals.dbUser.getUID());
                  DocumentSnapshot doc = await docRef.get();
                  setState(() {
                    List tags = doc.data['postLikeList'];

                    if(tags.contains(post.documentID)) {
                      _showDialog(true);
                    }
                    else {
                      _showDialog(false);
                      docRef.updateData({
                        'postLikeList': FieldValue.arrayUnion([post.documentID]),
                      });
                      post.reference.updateData({
                        'like': FieldValue.increment(1),
                      });
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

  Widget _buildComment(BuildContext context, DocumentSnapshot comment, String postDocID) {
    String content = comment['content'];
    String writer = comment['writerNick'];
    int like = comment['like'];
    Timestamp tt = comment['date'];
    String writerUID = comment['writer'];

    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);

    return Container(
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
                                    _commentDocID = comment.documentID;
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
                          _focusNode.requestFocus();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up_off_alt,
                        size: 20,
                      ),
                      onPressed: () async {
                        DocumentReference docRef = Firestore.instance.collection('user').document(globals.dbUser.getUID());
                        DocumentSnapshot doc = await docRef.get();
                        setState(() {
                          List tags = doc.data['commentLikeList'];

                          if(tags.contains(comment.documentID)) {
                            _showDialog(true);
                          }
                          else {
                            _showDialog(false);
                            docRef.updateData({
                              'commentLikeList': FieldValue.arrayUnion([comment.documentID]),
                            });
                            comment.reference.updateData({
                              'like': FieldValue.increment(1),
                            });
                          }
                        });
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
                      onSelected: (selectedMenu) {
                        switch(selectedMenu){
                          case 'message':
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context)=>
                                      chatRoomView(
                                        chatRoomID: "chatInit/"+writerUID,
                                        chatRoomName: "new message",
                                      ),
                                )
                            );
                            break;
                          default :
                            break;
                        }
                        print(selectedMenu);
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
    );
  }

  Widget _buildNestedComment(BuildContext context, DocumentSnapshot nestedComment) {
    String content = nestedComment['content'];
    String writer = nestedComment['writerNick'];
    int like = nestedComment['like'];
    Timestamp tt = nestedComment['date'];
    String writerUID = nestedComment['writer'];
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
                              DocumentReference docRef = Firestore.instance.collection('user').document(globals.dbUser.getUID());
                              DocumentSnapshot doc = await docRef.get();
                              setState(() {
                                List tags = doc.data['commentLikeList'];

                                if(tags.contains(nestedComment.documentID)) {
                                  _showDialog(true);
                                }
                                else {
                                  _showDialog(false);
                                  docRef.updateData({
                                    'commentLikeList': FieldValue.arrayUnion([nestedComment.documentID]),
                                  });
                                  nestedComment.reference.updateData({
                                    'like': FieldValue.increment(1),
                                  });
                                }
                              });
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
                            onSelected: (selectedMenu) {
                              switch(selectedMenu){
                                case 'message':
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context)=>
                                            chatRoomView(
                                              chatRoomID: "chatInit/"+writerUID,
                                              chatRoomName: "new message",
                                            ),
                                      )
                                  );
                                  break;
                                default :
                                  break;
                              }
                              print(selectedMenu);
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

  void _saveComment() async {
    CollectionReference colRef =  Firestore.instance.collection('comments').document(postDocID).collection('commentList');

    if(_commentDocID == 'null') {
      await colRef.add({
        'content': _commentController.text,
        'date': DateTime.now(),
        'like': 0,
        'writer': globals.dbUser.getUID(),
        'writerNick': globals.dbUser.getNickName(),
        'report': 0,
      });

      await Firestore.instance.collection('board').document(postDocID).updateData({
        'comments': FieldValue.increment(1),
      });
    }
    else {
      await colRef.document(_commentDocID).collection('nestedComment').add({
        'content': _commentController.text,
        'date': DateTime.now(),
        'like': 0,
        'writer': globals.dbUser.getUID(),
        'writerNick': globals.dbUser.getNickName(),
        'report': 0,
      });

      await Firestore.instance.collection('board').document(postDocID).updateData({
        'comments': FieldValue.increment(1),
      });

      _commentDocID = 'null';
    }

    _focusNode.unfocus();
    _commentController.clear();
  }

  void _showDialog(bool check) {
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
                  check ?
                  '이미 좋아요를 눌렀습니다.'
                      : '성공적으로 좋아요를 눌렀습니다.'
              ),
            ),
          ),
        );
      },
    );
  }
}