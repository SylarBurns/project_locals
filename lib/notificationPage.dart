import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'globals.dart' as globals;

import 'postView.dart';

final db = Firestore.instance;

class NotificationPage extends StatefulWidget {

  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  Timer _timer;
  bool changeColor = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
          changeColor = true;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _timer = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildNotificationPage(context);
  }

  Widget _buildNotificationPage(BuildContext context) {
    return FutureBuilder(
      future: db.collection('user').document(globals.dbUser.getUID()).collection('notification').getDocuments(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        else {
          return Expanded(
            child: ListView(
              children: snapshot.data.documents.map((notification) {
                String type = notification['type'];
                bool isRead = notification['isRead'];

                if(!isRead) {
                  notification.reference.updateData({
                    'isRead': true,
                  });
                }

                if(type == 'like') return _buildLikeNotifyTile(context, notification, isRead);
                else return _buildCommentNotifyTile(context, notification, isRead, type);
              }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildLikeNotifyTile(BuildContext context, DocumentSnapshot snapshot, bool isRead) {
    String writerNick = snapshot['writerNick'];
    String content = snapshot['content'];

    return AnimatedContainer(
      duration: Duration(seconds: 2),
      color: !isRead ? changeColor? Colors.white12 : Colors.black12 : Colors.white12,
      child: ListTile(
        leading: Icon(
          Icons.favorite,
          color: Colors.red,
        ),
        title: Text(
          '$writerNick님이 좋아요를 눌렀습니다.',
        ),
        subtitle: Text(
          '$content',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostView(
              postDocID: snapshot['postDocID'],
              boardName: '',
              boardType: snapshot['boardType'],
              writerUID: globals.dbUser.getUID(),
            )),
          );
        },
      ),
    );
  }

  Widget _buildCommentNotifyTile(BuildContext context, DocumentSnapshot snapshot, bool isRead, String type) {
    String writerNick = snapshot['writerNick'];
    String content = snapshot['content'];
    String comment = snapshot['comment'];

    return AnimatedContainer(
      duration: Duration(seconds: 2),
      color: !isRead ? changeColor ? Colors.white12 : Colors.black12 : Colors.white12,
      child: ListTile(
        leading: Icon(
          Icons.comment_outlined,
        ),
        title: Text(
          type == 'comment'?
          '$writerNick님이 댓글을 작성했습니다.'
              : '$writerNick님이 대댓글을 작성했습니다.',
        ),
        subtitle: Text(
          '$content: $comment',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostView(
              postDocID: snapshot['postDocID'],
              boardName: '',
              boardType: snapshot['boardType'],
              writerUID: globals.dbUser.getUID(),
            )),
          );
        },
      ),
    );
  }
}

