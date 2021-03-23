import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'globals.dart' as globals;

import 'chatRoomList.dart';
import 'notificationPage.dart';

final db = Firestore.instance;

class NotificationBody extends StatefulWidget {

  _NotificationBodyState createState() => _NotificationBodyState();
}

class _NotificationBodyState extends State<NotificationBody> {
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
                  await docRef.updateData({
                    'unreadNotification': 0,
                  });
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