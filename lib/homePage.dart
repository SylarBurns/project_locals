import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;
import 'ad_manager.dart';
import 'postList.dart';
import 'postView.dart';
final db = Firestore.instance;

class homePage extends StatefulWidget {
  const homePage({Key key}) : super(key: key);
  @override
  homePageState createState() => homePageState();
}

class homePageState extends State<homePage> {
  Refresh() {
    setState(() {});
  }

  List<String> boardTypes = [
    "free",
    "anonymous",
    "lostAndFound",
    "promo",
  ];
  List<DocumentSnapshot> hotPostList = List<DocumentSnapshot>();
  HashMap<String, List<DocumentSnapshot>> recentPostLists = HashMap<String, List<DocumentSnapshot>>();
  bool hotLoaded;
  bool recentLoaded;
  bool _isAdLoaded;
  BannerAd _ad;
  @override
  void initState() {
    hotLoaded = false;
    recentLoaded = false;
    _isAdLoaded = false;
    super.initState();
    getHotPosts();
    getRecentPosts();
    _ad = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: AdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();

          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );
    _ad.load();
  }
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }
  void getHotPosts() async {
    await db
        .collection('board')
        .where("region", isEqualTo: globals.dbUser.getSelectedRegion())
        .where('date',
        isGreaterThan: DateTime.now().subtract(Duration(days: 7)))
        .orderBy("date")
        .getDocuments()
        .then((value) {
      hotPostList = value.documents;
      hotPostList.sort((A, B) => -A['like'].compareTo(B['like']));
      if (hotPostList.length > 3) {
        hotPostList = hotPostList.sublist(0, 3);
      }
      setState(() {
        hotLoaded = true;
      });
    });
  }
  void getRecentPosts() async {
    await boardTypes.forEach((element) async {
      await db
          .collection("board")
          .where("region", isEqualTo: globals.dbUser.getSelectedRegion())
          .where("boardType", isEqualTo: element)
          .orderBy("date", descending: true)
          .limit(3)
          .getDocuments()
          .then((value){
        recentPostLists.addAll({
          element : value.documents,
        });
      });
      if(boardTypes.last == element){
        setState(() {
          recentLoaded = true;
        });
      }
    });
  }
  Future refreshHomePage() async {
    await getHotPosts();
    await getRecentPosts();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if(hotLoaded && recentLoaded && _isAdLoaded){
      print("loaded hot posts: "+hotPostList.length.toString());
      print("loaded recent posts: "+recentPostLists.length.toString());
      return RefreshIndicator(
        onRefresh: refreshHomePage,
        child: ListView(
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
              _buildHotPostList(context, hotPostList),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 60,
                width: _ad.size.width.toDouble(),
                child: AdWidget(ad: _ad,),
                alignment: Alignment.center,
              ),
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
            ]),
      );
    }else{
      return globals.getLoadingAnimation(context);
    }
  }
  Widget _buildHotPostList(
      BuildContext context, List<DocumentSnapshot> snapshots) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).accentColor.withOpacity(0.20),
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
    int comments = document['comments'];
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
      case "promo":
        boardName = "홍보 게시판";
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
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
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
                  Text('$date', style: TextStyle(color: Theme.of(context).accentTextTheme.bodyText1.color))
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
              Padding(padding: EdgeInsets.only(bottom: 4),),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '$boardName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).accentColor.withOpacity(0.65)
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 15,
                            color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65),
                          ),
                          Padding(padding: EdgeInsets.only(right: 2.0)),
                          Text(
                            '$like',
                            style:
                            TextStyle(color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65)),
                          ),
                          Padding(padding: EdgeInsets.only(right: 10.0)),
                          Icon(
                              Icons.comment_bank_outlined,
                              size: 15.0,
                              color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65)
                          ),
                          Padding(padding: EdgeInsets.only(right: 2.0)),
                          Text(
                            '$comments',
                            style: TextStyle(color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65)),
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
    return Column(
      children: List.generate(recentPostLists.length, (index) {
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
          case "promo":
            boardName = "홍보 게시판";
            break;
        }
        return Container(
          child: Column(
            children: [
              _buildRecentPostList(
                  context, recentPostLists[boardTypes[index]], boardName),
              SizedBox(
                height: 10,
              )
            ],
          ),
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
            color: Theme.of(context).accentColor.withOpacity(0.20),
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
    int comments = document["comments"];
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
                maxLines: 1,
              ),
            ),
            Padding(padding: EdgeInsets.only(bottom: 10.0),),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(date.toString(),
                  style: TextStyle(color:Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65)),),
                Container(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    children: [
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 15,
                        color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65),
                      ),
                      Padding(padding: EdgeInsets.only(right: 2.0)),
                      Text(
                        '$like',
                        style:
                        TextStyle(color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65)),
                      ),
                      Padding(padding: EdgeInsets.only(right: 10.0)),
                      Icon(
                          Icons.comment_bank_outlined,
                          size: 15.0,
                          color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65)
                      ),
                      Padding(padding: EdgeInsets.only(right: 2.0)),
                      Text(
                        '$comments',
                        style: TextStyle(color: Theme.of(context).accentTextTheme.bodyText1.color.withOpacity(0.65)),
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
