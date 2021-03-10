import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'postView.dart';
import 'postWrite.dart';

class _PostTile extends StatelessWidget {
  _PostTile({
    Key key,
    this.post,
    this.boardName,
}) : super(key: key);

  final DocumentSnapshot post;
  final String boardName;

  String getDate() {
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

  @override
  Widget build(BuildContext context) {
    String title = post['title'];
    String content = post['content'];
    String writer = post['writerNick'];
    int like = post['like'];
    int comments = post['comments'];
    String region = post['region'];
    String writerUID = post['writer'];
    String date = getDate();

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
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            Padding(padding: EdgeInsets.only(bottom: 2.0)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // '10 min ago |',
                  '$date | ',
                  style: TextStyle(
                    color: Colors.black45,
                  ),
                ),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Text(
                  '$writer',
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostView(postDocID: post.documentID, boardName: boardName, writerUID: writerUID,),
          ),
        ),
      ),
    );
  }
}

class FreeBoard extends StatefulWidget {
  final String boardName;
  final String boardType;

  FreeBoard({Key key, @required this.boardName, @required this.boardType,});

  @override
  _FreeBoardState createState() => _FreeBoardState(key: this.key, boardName: this.boardName, boardType: this.boardType,);
}

class _FreeBoardState extends State<FreeBoard> {
  String boardName;
  String boardType;

  _FreeBoardState({Key key, this.boardName, this.boardType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          '$boardName',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: Firestore.instance.collection("board").where("boardType", isEqualTo: boardType).orderBy('date', descending: true).snapshots(),
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

                  return _PostTile(
                    post: post,
                    boardName: boardName,
                  );
                }
            );
          } // switch
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostWrite(boardType: boardType,)),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}