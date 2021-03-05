import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;
final db = Firestore.instance;
class chatRoom extends StatefulWidget{
  @override
  _chatRoomState createState() => _chatRoomState();
}

class _chatRoomState extends State<chatRoom> {
  @override
  Widget build(BuildContext context) {
    return _chatRoomBody(context);
  }
  Widget _chatRoomBody(BuildContext context){
    return StreamBuilder(
        stream: db
            .collection("chatroom")
            .where("participants.uid", arrayContains: globals.dbUser.getUID().toString())
            .orderBy("lastDate", descending: true)
            .snapshots(),
        builder:(context, snapshot) {
          if(snapshot.connectionState == ConnectionState.none && snapshot.hasData == null){
            return Center(child: SizedBox(height: 5, width: 5,child: CircularProgressIndicator(),));
          }else if(snapshot.data!=null && snapshot.data.documents.length == 0){
            return Center(child: Text("no result"));
          }else if(snapshot.data!=null) {
            return _chatRoomList(context, snapshot.data.documents);
          }else{
            return Center(child: Text("no result"));
          }
        },
    );
  }
  Widget _chatRoomList(BuildContext context, List<DocumentSnapshot> documents){
    return ListView.builder(
        shrinkWrap: true,
        itemCount: documents.length,
        itemBuilder: (context, index){
          return _chatRoomItem(context, documents[index]);
        }
    );
  }
  Widget _chatRoomItem(BuildContext context, DocumentSnapshot document){
    List<dynamic> participants = document["participants"];
    participants.removeWhere((element) => element["uid"].toString() == globals.dbUser.getUID());
    String participantsString = "";
    if(participants.length > 0){
      participantsString = participants[0]["nickname"];
    }else{
      participantsString = "unknown";
    }
    if(participants.length>1){
      for(int i=1;i<participants.length;i++){
        participantsString = participantsString+", "+participants[i]["nickname"];
      }
    }
    Timestamp tt = document["lastDate"];
    DateTime dateTime =
    DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);
    return Container(
      padding: EdgeInsets.all(8),
      child: InkWell(
        onTap: ()=> print(document["participants"]),
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: Text(
                participantsString,
                style: TextStyle(
                  fontSize: 13
                ),
              ),
            ),
            Container(
              alignment:Alignment.bottomRight,
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 10
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}