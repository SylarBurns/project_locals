import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'postView.dart';
import 'postWrite.dart';
import 'ad_manager.dart';

import 'globals.dart' as globals;

class PostList extends StatefulWidget {
  final String boardName;
  final String boardType;

  PostList({Key key, @required this.boardName, @required this.boardType,});

  @override
  _PostListState createState() => _PostListState(key: this.key,);
}

class _PostListState extends State<PostList> {
  bool _isAdLoaded = false;
  bool _isDataLoaded = false;

  QuerySnapshot postQuery;

  _PostListState({Key key,});

  FutureOr refresh(dynamic value) {
    setState(() {});
  }

  BannerAd _bannerAd;

  void loadData() async {
    var ref = Firestore.instance.collection('board');
    await ref
        .where('region', isEqualTo: globals.dbUser.getSelectedRegion())
        .where("boardType", isEqualTo: widget.boardType)
        .orderBy('date', descending: true)
        .getDocuments().then((value) {
      postQuery = value;
    });

    _isDataLoaded = true;
    setState(() {});
  }

  void loadAd() async {
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: AdListener(
        onAdLoaded: (_) {
          _isAdLoaded = true;
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void initState() {
    super.initState();
    loadData();
    loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(
        '${widget.boardName}',
      ),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = appBar.preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final adHeight = AdSize.banner.height;

    return Scaffold(
      appBar: appBar,
      body: (_isDataLoaded) ? Column(
        children: [
          Container(
              height: (screenHeight - appBarHeight - statusBarHeight - adHeight - 10),
              child: ListView.separated(
                  itemCount: postQuery.documents.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    DocumentSnapshot post = postQuery.documents[index];
                    int report = post['report'];

                    if(report >= 10) {
                      return _buildBlindPost(context, post);
                    }
                    else {
                      return _buildPostTile(context, post);
                    }
                  }
              )
          ),
          Container(
            height: adHeight.toDouble()+10,
            child: AdWidget(ad: _bannerAd,),
            alignment: Alignment.center,
          ),
        ],
      ) : globals.getLoadingAnimation(context),
      floatingActionButton: globals.dbUser.getAuthority() ? Padding(
        padding: EdgeInsets.only(bottom:50),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostWrite(boardType: widget.boardType,)),
            ).then(refresh);
          },
          child: Icon(Icons.add),
        ),
      ) : null,
    );
  }

  String _getDate(DocumentSnapshot post) {
    Timestamp tt = post['date'];

    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    DateTime curTime = DateTime.now();

    if(dateTime.difference(curTime).inDays == 0) {
      return DateFormat.Hm().format(dateTime);
    }
    else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }

  Widget _buildPostTile(BuildContext context, DocumentSnapshot post) {
    String title = post['title'];
    String content = post['content'];
    String writer = post['writerNick'];
    int like = post['like'];
    int comments = post['comments'];
    String writerUID = post['writer'];
    String date = _getDate(post);
    bool isEdit = post['isEdit'];

    return Padding(
      padding: EdgeInsets.all(5.0),
      child: ListTile(
        title: Text(
          '$title',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$content',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.0,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$date | ',
                  style: TextStyle(
                    color: Theme.of(context).accentColor.withOpacity(0.45)
                  ),
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  isEdit ? '$writer | (edited)' : '$writer',
                  style: TextStyle(
                    color: Theme.of(context).accentColor.withOpacity(0.45)
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 15.0,
                    color: Theme.of(context).accentColor.withOpacity(0.45)
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  '$like',
                  style: TextStyle(color: Theme.of(context).accentColor.withOpacity(0.45)),
                ),
                Padding(padding: EdgeInsets.only(right: 10.0)),
                Icon(
                  Icons.comment_bank_outlined,
                  size: 15.0,
                    color: Theme.of(context).accentColor.withOpacity(0.45)
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                    '$comments',
                  style: TextStyle(color: Theme.of(context).accentColor.withOpacity(0.45)),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostView(
                postDocID: post.documentID,
                boardName: widget.boardName,
                boardType: widget.boardType,
                writerUID: writerUID,
              ),
            ),
          ).then((value) {
            refresh(value);
          });
        },
      ),
    );
  }

  Widget _buildBlindPost(BuildContext context, DocumentSnapshot post) {
    int like = post['like'];
    int comments = post['comments'];
    String writerUID = post['writer'];
    String date = _getDate(post);
    String boardType = post['boardType'];

    return Padding(
      padding: EdgeInsets.all(5.0),
      child: ListTile(
        title: Text(
          '신고가 누적되어 블라인드 처리된 게시글입니다.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ' ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 2.0,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$date | ',
                  style: TextStyle(
                    color: Theme.of(context).accentColor.withOpacity(0.45),
                  ),
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  '(Blind)',
                  style: TextStyle(
                    color: Colors.black45,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 15.0,
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  '$like',
                ),
                Padding(padding: EdgeInsets.only(right: 10.0)),
                Icon(
                  Icons.comment_bank_outlined,
                  size: 15.0,
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                    '$comments'
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          bool result = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)
                ),

                content: Text('게시글을 열람하시겠습니까?'),
                actions: [
                  FlatButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                ],
              );
            },
          );
          if(result) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostView(
                  postDocID: post.documentID,
                  boardName: widget.boardName,
                  boardType: widget.boardType,
                  writerUID: writerUID,
                ),
              ),
            ).then(refresh);
          }
        },
      ),
    );
  }
}