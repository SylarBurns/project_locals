import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'postView.dart';
import 'postWrite.dart';

import 'globals.dart' as globals;

class PostList extends StatefulWidget {
  final String boardName;
  final String boardType;

  PostList({
    Key key,
    @required this.boardName,
    @required this.boardType,
  });

  @override
  _PostListState createState() => _PostListState(
        key: this.key,
      );
}

class _PostListState extends State<PostList> {
  bool _isDataLoaded = false;
  bool _hasMore = true;
  int documentLimit = 10;
  ScrollController _scrollController = ScrollController();
  DocumentSnapshot lastDocument;
  List<DocumentSnapshot> posts = [];
  QuerySnapshot postQuery;

  _PostListState({
    Key key,
  });

  FutureOr refresh(dynamic value) {
    loadData();
  }

  Future refreshPost() async {
    setState(() {
      posts.clear();
      lastDocument = null;
      postQuery = null;
      _hasMore = true;
      _isDataLoaded = false;
    });

    await loadData();
  }

  void loadData() async {
    if (!_hasMore) {
      return;
    }

    var ref = Firestore.instance.collection('board');

    if(lastDocument == null) {
      await ref
          .where('region', isEqualTo: globals.dbUser.getSelectedRegion())
          .where("boardType", isEqualTo: widget.boardType)
          .orderBy('date', descending: true)
          .limit(documentLimit)
          .getDocuments()
          .then((value) {
        postQuery = value;
      });
    }
    else {
      await ref
          .where('region', isEqualTo: globals.dbUser.getSelectedRegion())
          .where("boardType", isEqualTo: widget.boardType)
          .orderBy('date', descending: true)
          .startAfterDocument(lastDocument)
          .limit(documentLimit)
          .getDocuments()
          .then((value) {
        postQuery = value;
      });
    }

    if (postQuery.documents.length < documentLimit) {
      _hasMore = false;
    }

    lastDocument = postQuery.documents[postQuery.documents.length - 1];
    posts.addAll(postQuery.documents);
    _isDataLoaded = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadData();

    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      if(currentScroll == maxScroll && _hasMore) {
        loadData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(
        '${widget.boardName}',
      ),
    );

    return Scaffold(
      appBar: appBar,
      body: (_isDataLoaded)
          ? RefreshIndicator(
              onRefresh: refreshPost,
              child: Container(
                padding: EdgeInsets.only(top: 15),
                child: ListView.separated(
                    controller: _scrollController,
                    itemCount: _hasMore ? posts.length+1 : posts.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      if(index == posts.length) {
                        return globals.getLoadingAnimation(context);
                      }
                      else {
                        DocumentSnapshot post = posts[index];
                        int report = post['report'];

                        if (report >= 10) {
                          return _buildBlindPost(context, post);
                        } else {
                          return _buildPostTile(context, post);
                        }
                      }
                    }),
              ),
            )
          : globals.getLoadingAnimation(context),
      floatingActionButton: globals.dbUser.getAuthority()
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostWrite(
                            boardType: widget.boardType,
                          )),
                ).then(refresh);
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  String _getDate(DocumentSnapshot post) {
    Timestamp tt = post['date'];

    DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    DateTime curTime = DateTime.now();

    if (dateTime.difference(curTime).inDays == 0) {
      return DateFormat.Hm().format(dateTime);
    } else {
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
            SizedBox(
              height: 2.0,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$date | ',
                  style: TextStyle(
                      color: Theme.of(context)
                          .accentTextTheme
                          .bodyText1
                          .color
                          .withOpacity(0.65)),
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  isEdit ? '$writer | (edited)' : '$writer',
                  style: TextStyle(
                      color: Theme.of(context)
                          .accentTextTheme
                          .bodyText1
                          .color
                          .withOpacity(0.65)),
                ),
                Spacer(),
                Icon(Icons.thumb_up_alt_outlined,
                    size: 15.0,
                    color: Theme.of(context)
                        .accentTextTheme
                        .bodyText1
                        .color
                        .withOpacity(0.65)),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  '$like',
                  style: TextStyle(
                      color: Theme.of(context)
                          .accentTextTheme
                          .bodyText1
                          .color
                          .withOpacity(0.65)),
                ),
                Padding(padding: EdgeInsets.only(right: 10.0)),
                Icon(Icons.comment_bank_outlined,
                    size: 15.0,
                    color: Theme.of(context)
                        .accentTextTheme
                        .bodyText1
                        .color
                        .withOpacity(0.65)),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  '$comments',
                  style: TextStyle(
                      color: Theme.of(context)
                          .accentTextTheme
                          .bodyText1
                          .color
                          .withOpacity(0.65)),
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
          ).then(refresh);
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
            SizedBox(
              height: 2.0,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$date | ',
                  style: TextStyle(
                    color: Theme.of(context)
                        .accentTextTheme
                        .bodyText1
                        .color
                        .withOpacity(0.65),
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
                Text('$comments'),
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
                    borderRadius: BorderRadius.circular(8.0)),
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
          if (result) {
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
