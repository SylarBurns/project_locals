import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;
import 'postList.dart';
import 'postView.dart';
final db = Firestore.instance;

class homePage extends StatefulWidget {
  const homePage({Key key}) : super(key: key);
  @override
  homePageState createState() => homePageState();
}

class homePageState extends State<homePage> {
  Refresh(){setState(() {});}
  List<String> boardTypes = [
    "free",
    "anonymous",
    "lostAndFound",
  ];
  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        children: <Widget>[
          SizedBox(
            height: 10,
          ),
          Container(
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.all(8),
            child: Text(
              "실시간 인기 글 ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _hotPost(context),
          SizedBox(
            height: 10,
          ),
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
          _recentPost(context),
        ]);
  }
  Future getHotPosts() async {
    List<DocumentSnapshot> docs = await db.collection('board')
        .where("region", isEqualTo: globals.dbUser.getSelectedRegion())
        .where('date', isGreaterThan: DateTime.now().subtract(Duration(days: 7)))
        .orderBy("date").getDocuments().then((value){
          List<DocumentSnapshot> docs = value.documents;
          docs.sort((A,B)=>-A['like'].compareTo(B['like']));
          if(docs.length>3){
            return docs.sublist(0,3);
          }else {
            return docs;
          }
    });
    return docs;
  }
  Widget _hotPost(BuildContext context) {
    return FutureBuilder(
      future: getHotPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting){
          return LinearProgressIndicator();
        }else if(snapshot.hasData){
          return _buildHotPostList(context, snapshot.data);
        }else{
          return LinearProgressIndicator();
        }
      },
    );
  }

  Widget _buildHotPostList(
      BuildContext context, List<DocumentSnapshot> snapshots) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withOpacity(0.20),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: snapshots
            .map((data) => _buildHotPostListItem(context, data))
            .toList(),
      ),
    );
  }

  Widget _buildHotPostListItem(
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
    String boardName = "";
    switch (boardT) {
      case "free":
        boardName = "자유 게시판";
        break;
      case "anonymous":
        boardName = "익명 게시판";
        break;
      case "lostAndFound":
        boardName = "Lost&Found";
        break;
    }
    return Container(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostView(postDocID: document.documentID, boardName: boardName, boardType: document["boardType"], writerUID: document['writer'],),
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
                      '$boardName',
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
                            color: Theme.of(context).primaryColor,
                          ),
                          Padding(padding: EdgeInsets.only(right: 2.0)),
                          Text(
                            '$like',
                            style:
                                TextStyle(fontSize: 12, color: Theme.of(context).primaryColor),
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

  Widget _recentPost(BuildContext context) {
    List<String> boardTypes = [
      "free",
      "anonymous",
      "lostAndFound",
    ];
    return Column(
      children: List.generate(boardTypes.length, (index) {
        String boardName = "";
        switch (boardTypes[index]) {
          case "free":
            boardName = "자유 게시판";
            break;
          case "anonymous":
            boardName = "익명 게시판";
            break;
          case "lostAndFound":
            boardName = "Lost&Found";
            break;
        }
        return StreamBuilder(
          stream: db
              .collection("board")
              .where("region", isEqualTo: globals.dbUser.getSelectedRegion())
              .where("boardType", isEqualTo: boardTypes[index])
              .orderBy("date", descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return LinearProgressIndicator();

            return Container(
              child: Column(
                children: [
                  _buildRecentPostList(
                      context, snapshot.data.documents, boardName),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildRecentPostList(BuildContext context,
      List<DocumentSnapshot> snapshots, String boardName) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black.withOpacity(0.20),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: <Widget>[
        Container(
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(8),
          child: Text(
            boardName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          child: Column(
            children: snapshots
                .map((data) => _buildRecentPostListItem(context, data, boardName))
                .toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildRecentPostListItem(
      BuildContext context, DocumentSnapshot document, String boardName) {
    String title = document["title"];
    Timestamp tt = document["date"];
    DateTime dateTime =
        DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = "";
    if (DateTime.now().difference(dateTime) <= new Duration(hours: 24)) {
      date = DateFormat.Hm().format(dateTime);
    } else {
      date = DateFormat.Md().format(dateTime);
    }
    int like = document["like"];
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostView(postDocID: document.documentID, boardName: boardName, boardType: document["boardType"], writerUID: document['writer'],),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                        color: Theme.of(context).primaryColor,
                      ),
                      Padding(padding: EdgeInsets.only(right: 2.0)),
                      Text(
                        like.toString(),
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
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
  }
}
