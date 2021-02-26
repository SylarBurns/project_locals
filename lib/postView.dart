import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class _Post extends StatelessWidget {
  _Post ({
    Key key,
    this.title,
    this.content,
    this.writer,
    this.like,
    this.comments,
    this.tt,
}) : super(key: key);
  final String title;
  final String content;
  final String writer;
  final int like;
  final int comments;
  final Timestamp tt;

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  print('like');
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

class PostView extends StatefulWidget {
  final DocumentSnapshot post;
  final String boardName;

  PostView({Key key, @required this.post, @required this.boardName,});

  _PostViewState createState() => _PostViewState(key: this.key, post: this.post, boardName: this.boardName, );
}

class _PostViewState extends State<PostView> {
  DocumentSnapshot post;
  String boardName;

  _PostViewState({Key key, this.post, this.boardName, });

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
          _Post(
            title: post['title'],
            content: post['content'],
            writer: post['writer'],
            like: post['like'],
            comments: 0,
            tt: post['date'],
          ),
        ],
      ),
    );
  }
}