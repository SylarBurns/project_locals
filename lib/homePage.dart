import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';
class homePage extends StatefulWidget{
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List<String> boardTypes = ["free", "anonymous", "lostAndFound",];
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      children: <Widget>[
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(8),
          child: Text(
            "실시간 인기 글",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.60),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),

          ),
          child: Column(
            children:<Widget>[
              StreamBuilder<QuerySnapshot>(
                stream: Firestore.instance.collection("board")
                    .orderBy("like", descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                  if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                  switch (snapshot.connectionState){
                    case ConnectionState.waiting: return Text("Loading...");
                    default:
                      return Column(
                        children: snapshot.data.documents.map((DocumentSnapshot document){
                          String title = document["title"];
                          String writer = document["writer"];
                          Timestamp tt = document["date"];
                          DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
                          String date = DateFormat.Md().add_Hm().format(dateTime);
                          int like = document["like"];
                          String content = document["content"];
                          String boardT = document["boardType"];
                          String boardType = "";
                          switch(boardT){
                            case "free": boardType = "자유 게시판"; break;
                            case "anonymous": boardType = "익명 게시판"; break;
                            case "lostAndFound": boardType = "Lost&Found"; break;
                          }
                          return InkWell(
                            onTap: () => print(title),
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
                                              Text(
                                                  writer,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold
                                                  )
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(date)
                                      ],
                                    ),
                                    Padding(padding: EdgeInsets.only(top: 3.0)),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.fromLTRB(0, 1, 0, 1),
                                      height: 30,
                                      child: Text(
                                        content,
                                        style: TextStyle(
                                          fontSize: 12
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    Container(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text(
                                            boardType,
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
                                                  like.toString(),
                                                  style: TextStyle(
                                                      color: Colors.red[800],
                                                      fontSize: 12
                                                  ),
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
                          );
                        }).toList(),
                      );
                  }
                },
              ),
            ]
          ),
        ),
        SizedBox(height: 10,),
        Container(
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(8),
          child: Text(
            "게시판 별 최신 글",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Column(
          children: List.generate(boardTypes.length, (index){
            String boardType = "";
            switch(boardTypes[index]){
              case "free": boardType = "자유 게시판"; break;
              case "anonymous": boardType = "익명 게시판"; break;
              case "lostAndFound": boardType = "Lost&Found"; break;
            }
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withOpacity(0.60),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                      children:<Widget>[
                        Container(
                          alignment: Alignment.bottomLeft,
                          padding: EdgeInsets.all(8),
                          child: Text(
                            boardType,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: Firestore.instance.collection("board")
                              .where("boardType", isEqualTo: boardTypes[index])
                              .orderBy("date", descending: true)
                              .limit(3)
                              .snapshots(),
                          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                            if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                            switch (snapshot.connectionState){
                              case ConnectionState.waiting: return Text("Loading...");
                              default:
                                return Column(
                                  children: snapshot.data.documents.map((DocumentSnapshot document){
                                    String title = document["title"];
                                    Timestamp tt = document["date"];
                                    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
                                    String date = "";
                                    if(DateTime.now().difference(dateTime)<=new Duration(hours: 24)){
                                      date = DateFormat.Hm().format(dateTime);
                                    }else{
                                      date = DateFormat.Md().format(dateTime);
                                    }
                                    int like = document["like"];
                                    return InkWell(
                                      onTap: () => print(title),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          children: <Widget>[
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: <Widget>[
                                                Text(date.toString()),
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
                                                        like.toString(),
                                                        style: TextStyle(
                                                            color: Colors.red[800],
                                                            fontSize: 12
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                            Padding(padding: EdgeInsets.only(top: 3.0))
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                            }
                          },
                        ),
                      ]
                  ),
                ),
                SizedBox(height: 10,)
              ],
            );
          }),
        ),
      ]
    );
  }
}