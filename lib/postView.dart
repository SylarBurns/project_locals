import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'globals.dart' as globals;

final scaffoldKey = GlobalKey<ScaffoldState>();

class _Post extends StatelessWidget {
  _Post ({
    Key key,
    // this.postDocID,
    this.post,
}) : super(key: key);

  // final String postDocID;
  final DocumentSnapshot post;

  @override
  Widget build(BuildContext context) {
    String title = post['title'];
    String content = post['content'];
    String writer = post['writerNick'];
    int like = post['like'];
    int comments = post['comments'];
    Timestamp tt = post['date'];

    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);

    return Padding(
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
                  List tags = doc.data['likeList'];

                  if(tags.contains(post.documentID)) {
                    scaffoldKey.currentState
                        .showSnackBar(SnackBar(content: Text("Already liked it")));
                  }
                  else {
                    docRef.updateData({
                      'likeList': FieldValue.arrayUnion([post.documentID]),
                    });
                    Firestore.instance.collection('board').document(post.documentID).updateData({
                      'like': FieldValue.increment(1),
                    });
                    scaffoldKey.currentState
                        .showSnackBar(SnackBar(content: Text("Successfully liked")));
                  }
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

class _Comment extends StatelessWidget {
  _Comment({
    Key key,
    this.comment,
}) : super(key: key);

  final DocumentSnapshot comment;

  @override
  Widget build(BuildContext context) {
    String content = comment['content'];
    String writer = comment['writerNick'];
    int like = comment['like'];
    Timestamp tt = comment['date'];

    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);

    return Padding(
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
                  // DocumentReference docRef = Firestore.instance.collection('user').document(globals.dbUser.getUID());
                  // DocumentSnapshot doc = await docRef.get();
                  // List tags = doc.data['likeList'];
                  //
                  // if(tags.contains(post.documentID)) {
                  //   scaffoldKey.currentState
                  //       .showSnackBar(SnackBar(content: Text("Already liked it")));
                  // }
                  // else {
                  //   docRef.updateData({
                  //     'likeList': FieldValue.arrayUnion([post.documentID]),
                  //   });
                  //   Firestore.instance.collection('board').document(post.documentID).updateData({
                  //     'like': FieldValue.increment(1),
                  //   });
                  //   scaffoldKey.currentState
                  //       .showSnackBar(SnackBar(content: Text("Successfully liked")));
                  // }
                },
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
}

class PostView extends StatefulWidget {
  final String postDocID;
  final String boardName;

  PostView({Key key, @required this.postDocID, @required this.boardName,});

  _PostViewState createState() => _PostViewState(
    key: this.key,
    postDocID: this.postDocID,
    boardName: this.boardName,
  );
}

class _PostViewState extends State<PostView> {
  String postDocID;
  String boardName;

  _PostViewState({Key key, this.postDocID, this.boardName,});

  DocumentSnapshot post;
  QuerySnapshot commentList;
  final commentController = TextEditingController();

  void loadData() async {
    post = await Firestore.instance.collection('board').document(postDocID).get();
    commentList = await Firestore.instance.collection('comments').document(postDocID).collection('commentList').getDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
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
          IconButton(
            icon: Icon(
              Icons.more_vert,
              semanticLabel: 'more',
            ),
            color: Colors.black,
            onPressed: () {
              print('more');
            },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          FutureBuilder(
            future: Firestore.instance.collection('board').document(postDocID).get(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData == false) {
                return CircularProgressIndicator();
              }
              else {
                return _Post(
                  post: snapshot.data,
                );
              }
            },
          ),
          // Divider(),
          FutureBuilder(
            future: Firestore.instance.collection('comments').document(postDocID).collection('commentList').getDocuments(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              else {
                return Column(
                  children: snapshot.data.documents.map((comment) {
                    return Column(
                      children: [
                        Divider(),
                        _Comment(
                          comment: comment,
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
      bottomSheet: Padding(
        padding: EdgeInsets.all(8.0),
        child: TextField(
          controller: commentController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Write a comment',
            filled: true,
            fillColor: Colors.black12,
            suffixIcon: IconButton(
              icon: Icon(Icons.send_rounded,),
              onPressed: () {
                print('comment');
              },
            ),
          ),
        ),
      ),
    );
  }
}