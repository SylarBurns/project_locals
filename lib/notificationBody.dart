import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'globals.dart' as globals;

import 'chatRoomList.dart';
import 'notificationPage.dart';

final db = Firestore.instance;

class NotificationBody extends StatefulWidget {
  const NotificationBody({Key key}) : super(key: key);
  NotificationBodyState createState() => NotificationBodyState();
}

class NotificationBodyState extends State<NotificationBody> {
  Refresh(){setState(() {});}
  bool _isChat = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Row(
            children: [
              InkWell(
                child: _isChat ?
                Text(
                  'Message',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    decoration: TextDecoration.underline,
                  ),
                )
                    : Text(
                  'Message',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 23,
                  ),
                ),
                onTap: () {
                  _isChat = true;
                  setState(() {});
                },
              ),
              SizedBox(width: 20.0,),
              InkWell(
                child: !_isChat ?
                Text(
                  'Notification',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    decoration: TextDecoration.underline,
                  ),
                )
                    : Text(
                  'Notification',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 23,
                  ),
                ),
                onTap: () async {
                  _isChat = false;
                  DocumentReference docRef = db.collection('user').document(globals.dbUser.getUID());
                  DocumentSnapshot snapshot = await docRef.get();
                  int unread = snapshot['unreadNotification'] * (-1);
                  if(unread != 0) {
                    await docRef.updateData({
                      'unreadNotification': 0,
                      'unreadCount': FieldValue.increment(unread),
                    });
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        _isChat ?
            chatRoomList()
          : NotificationPage(),
      ],
    );
  }
}