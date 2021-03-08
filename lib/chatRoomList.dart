import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chatRoomView.dart';
import 'globals.dart' as globals;
final db = Firestore.instance;
class chatRoomList extends StatefulWidget{
  @override
  _chatRoomListState createState() => _chatRoomListState();
}

class _chatRoomListState extends State<chatRoomList> {
  @override
  Widget build(BuildContext context) {
    return _chatRoomBody(context);
  }
  Widget _chatRoomBody(BuildContext context){
    return StreamBuilder(
        stream: db
            .collection("chatroom")
            .where("participants", arrayContains: globals.dbUser.getUID().toString())
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
    return Container(
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.topCenter,
      child: ListView.builder(
        padding: EdgeInsets.all(10),
          shrinkWrap: true,
          itemCount: documents.length,
          itemBuilder: (context, index){
            return _chatRoomItem(context, documents[index]);
          }
      ),
    );
  }
  Widget _chatRoomItem(BuildContext context, DocumentSnapshot document){
    List<dynamic> participants = document["participants"];
    List<dynamic> participantsNick = [];
    participants.removeWhere((element) => element.toString() == globals.dbUser.getUID());
    Future _getParticipantsNick() async{
      String participantsString = "";
      if(participants.length > 0){
        DocumentSnapshot ds = await db.collection('user').document(participants[0]).get();
        participantsString = ds["nickName"];
      }else{
        participantsString = "unknown";
      }
      if(participants.length>1){
        for(int i=1;i<participants.length;i++){
          DocumentSnapshot ds = await db.collection('user').document(participants[i]).get();
          participantsString = participantsString+", "+ds['nickName'];
        }
      }
      return participantsString;
    }
    Timestamp tt = document["lastDate"];
    DateTime dateTime =
    DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);
    return Container(
      padding: EdgeInsets.all(8),
      child: FutureBuilder(
        future: _getParticipantsNick(),
        builder: (context, result){
          return InkWell(
          onTap: () =>{
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context)=>
                        chatRoomView(
                            chatRoomID: document.documentID,
                            chatRoomName: result.data.toString(),
                        ),
                )
            ),
          },
          child: Column(
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  result.data.toString(),
                  style: TextStyle(
                      fontSize: 13
                  ),
                ),
              ),
              Container(
                alignment: Alignment.bottomRight,
                child: Text(
                  date,
                  style: TextStyle(
                      fontSize: 10
                  ),
                ),
              )
            ],
          ),
        );
        }
      ),
    );
  }
}