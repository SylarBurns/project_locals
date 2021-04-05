import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'postView.dart';
import 'postWrite.dart';
import 'ad_manager.dart';

import 'globals.dart' as globals;

class PostList extends StatefulWidget {
  final String boardName;
  final String boardType;

  PostList({Key key, @required this.boardName, @required this.boardType,});

  @override
  _PostListState createState() => _PostListState(key: this.key, boardName: this.boardName, boardType: this.boardType,);
}

class _PostListState extends State<PostList> {
  String boardName;
  String boardType;

  _PostListState({Key key, this.boardName, this.boardType});

  FutureOr refresh(dynamic value) {
    setState(() {});
  }

  BannerAd _bannerAd;

  void _loadBannerAd() {
    _bannerAd
      ..load()
      ..show(anchorType: AnchorType.bottom);
  }

  void initializeAd() {
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
    );
    _loadBannerAd();
  }   

  @override
  void initState() {
    super.initState();
    initializeAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$boardName',
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 60),
        child: FutureBuilder(
          future: Firestore.instance
              .collection("board")
              .where('region', isEqualTo: globals.dbUser.getSelectedRegion())
              .where("boardType", isEqualTo: boardType)
              .orderBy('date', descending: true)
              .getDocuments(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return Text("Error: ${snapshot.error}");
            switch (snapshot.connectionState) {
              case ConnectionState.waiting: return Center(child: CircularProgressIndicator());
              default:
                return ListView.separated(
                    itemCount: snapshot.data.documents.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      DocumentSnapshot post = snapshot.data.documents[index];
                      int report = post['report'];

                      if(report >= 10) {
                        return _buildBlindPost(context, post);
                      }
                      else {
                        return _buildPostTile(context, post);
                      }
                    }
                );
            } // switch
          },
        ),
      ),
      floatingActionButton: globals.dbUser.getAuthority() ? Padding(
        padding: EdgeInsets.only(bottom:50),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostWrite(boardType: boardType,)),
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
    String region = post['region'];
    String writerUID = post['writer'];
    String date = _getDate(post);
    bool isEdit = post['isEdit'];
    String boardType = post['boardType'];

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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostView(
                postDocID: post.documentID,
                boardName: boardName,
                boardType: boardType,
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
                    color: Colors.black45,
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
                  boardName: boardName,
                  boardType: boardType,
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