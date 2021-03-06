import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chatRoomView.dart';
import 'package:badges/badges.dart';
import 'globals.dart' as globals;

final db = Firestore.instance;

class chatRoomList extends StatefulWidget {
  @override
  _chatRoomListState createState() => _chatRoomListState();
}

class _chatRoomListState extends State<chatRoomList> {
  @override
  Widget build(BuildContext context) {
    return _chatRoomBody(context);
  }

  Widget _chatRoomBody(BuildContext context) {
    return StreamBuilder(
      stream: db
          .collection("chatroom")
          .where("participants",
              arrayContains: globals.dbUser.getUID().toString())
          .orderBy("lastDate", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.none &&
            snapshot.hasData == null) {
          return Center(
              child: SizedBox(
            height: 5,
            width: 5,
            child: CircularProgressIndicator(),
          ));
        } else if (snapshot.data != null &&
            snapshot.data.documents.length == 0) {
          return Center(child: Text("no result"));
        } else if (snapshot.data != null) {
          return _chatRoomList(context, snapshot.data.documents);
        } else {
          return Center(child: Text("no result"));
        }
      },
    );
  }

  Widget _chatRoomList(BuildContext context, List<DocumentSnapshot> documents) {
    return Expanded(
      // height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return _chatRoomItem(context, documents[index]);
            }),
      ),
    );
  }

  Widget _chatRoomItem(BuildContext context, DocumentSnapshot document) {
    List<dynamic> participants = document["participants"];
    participants.removeWhere(
        (element) => element.toString() == globals.dbUser.getUID());
    Future _getInitialData() async {
      String participantsString = "";
      if (document['isAnonymous']) {
        participantsString = "익명";
      } else {
        if (participants.length > 0) {
          DocumentSnapshot ds =
              await db.collection('user').document(participants[0]).get();
          participantsString = ds["nickName"];
        } else {
          participantsString = "unknown";
        }
        if (participants.length > 1) {
          for (int i = 1; i < participants.length; i++) {
            DocumentSnapshot ds =
                await db.collection('user').document(participants[i]).get();
            participantsString = participantsString + ", " + ds['nickName'];
          }
        }
      }
      return participantsString;
    }

    Timestamp tt = document["lastDate"];
    DateTime dateTime =
        DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);
    return Container(
      padding: EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: FutureBuilder(
          future: _getInitialData(),
          builder: (context, result) {
            if (result.hasData) {
              return InkWell(
                onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => chatRoomView(
                          chatRoomID: document.documentID,
                          chatRoomName: result.data.toString(),
                        ),
                      )),
                },
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          alignment: Alignment.topLeft,
                          child: Text(
                            result.data.toString(),
                            style: TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          child: document['unreadCount']
                                      [globals.dbUser.getUID()] >=
                                  1
                              ? Badge(
                                  badgeContent: Text(
                                    document['unreadCount']
                                                [globals.dbUser.getUID()] >
                                            99
                                        ? "99+"
                                        : document['unreadCount']
                                                [globals.dbUser.getUID()]
                                            .toString(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  badgeColor: Colors.pinkAccent,
                                )
                              : SizedBox(
                                  width: 1,
                                  height: 1,
                                ),
                        )
                      ],
                    ),
                    Padding(padding: EdgeInsets.only(bottom: 5.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Text(
                            document['lastMessage'],
                            style: TextStyle(
                              color: Theme.of(context)
                                  .accentTextTheme
                                  .bodyText1
                                  .color
                                  .withOpacity(0.65),
                              fontSize: 10,
                              fontWeight: document['unreadCount']
                                          [globals.dbUser.getUID()] >
                                      1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        Container(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            date,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .accentTextTheme
                                  .bodyText1
                                  .color
                                  .withOpacity(0.65),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            } else {
              return LinearProgressIndicator();
            }
          }),
    );
  }
}
