import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'postView.dart';
import 'package:rxdart/rxdart.dart';
import 'globals.dart' as globals;
final db = Firestore.instance;

class likeList extends StatefulWidget{
  @override
  _likeListState createState() => _likeListState();
}

class _likeListState extends State<likeList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
          ),
        title: Text("내가 좋아요 누른 글", style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,),
      body: _likedPost(context)
    );
  }
  Future getLikedPosts() async {
    List<DocumentSnapshot> result = await db.collection('user').document(globals.dbUser.getUID()).get()
        .then((value) async {
          List<dynamic> likedIDList = value["postLikeList"];
          List<DocumentSnapshot> likedPostList = List<DocumentSnapshot>();
          await Future.forEach(likedIDList,(element) async {
            await db.collection('board').document(element).get().then((value){
              likedPostList.add(value);
            });
          });
          return likedPostList;
        });
    return result;
  }
  Widget _likedPost(BuildContext context) {
    return FutureBuilder(
      future: getLikedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting){
          return LinearProgressIndicator();
        }else if(snapshot.hasData){
          return _buildlikedPostList(context, snapshot.data);
        }else if(snapshot.data.length == 0){
          return Center(child: Text("좋아요 누른 글이 없습니다"));
        }else{
          return LinearProgressIndicator();
        }
      },
    );
  }

  Widget _buildlikedPostList(
      BuildContext context, List<DocumentSnapshot> documents) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index){
            return _buildlikedPostItem(context, documents[index]);
          }
      )
    );
  }

  Widget _buildlikedPostItem(
      BuildContext context, DocumentSnapshot document) {
    String title = document["title"];
    String writer = document["writerNick"];
    Timestamp tt = document["date"];
    DateTime dateTime =
    DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);
    int like = document["like"];
    String content = document["content"];
    String boardT = document["boardType"];
    String boardType = "";
    switch (boardT) {
      case "free":
        boardType = "자유 게시판";
        break;
      case "anonymous":
        boardType = "익명 게시판";
        break;
      case "lostAndFound":
        boardType = "Lost&Found";
        break;
    }
    return Container(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostView(postDocID: document.documentID, boardType:document["boardType"],boardName: boardType, writerUID: document['writer'],),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        Text('$writer',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text('$date')
                ],
              ),
              Padding(padding: EdgeInsets.only(top: 3.0)),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$title',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.fromLTRB(0, 1, 0, 1),
                height: 30,
                child: Text(
                  '$content',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$boardType',
                      style: TextStyle(
                        color: Colors.black26.withOpacity(.70),
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 10,
                            color: Colors.red[800],
                          ),
                          Padding(padding: EdgeInsets.only(right: 2.0)),
                          Text(
                            '$like',
                            style:
                            TextStyle(color: Colors.red[800], fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}