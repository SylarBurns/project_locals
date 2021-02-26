import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _PostView extends StatelessWidget {
  _PostView({
    Key key,
    this.title,
    this.content,
    // this.date,
    this.writer,
    this.like,
    this.comments,
}) : super(key: key);

  final String title;
  final String content;
  // final DateTime date;
  final String writer;
  final int like;
  final int comments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2.0),
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
                  '10 min ago |',
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
      ),
    );
  }
}

class FreeBoard extends StatefulWidget {
  @override
  _FreeBoardState createState() {
    return _FreeBoardState();
  }
}

class _FreeBoardState extends State<FreeBoard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Free Board')),
      body: StreamBuilder(
        stream: Firestore.instance.collection("board").where("boardType", isEqualTo: "free").snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return Text("Error: ${snapshot.error}");
          switch (snapshot.connectionState) {
            case ConnectionState.waiting: return Center(child: CircularProgressIndicator());
            default:
              return ListView.separated(
                itemCount: snapshot.data.documents.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data.documents[index];
                  String region = document['region'];
                  Timestamp tt = document['date'];

                  return _PostView(
                    title: document['title'],
                    content: document['content'],
                    writer: document['writer'],
                    like: document['like'],
                    comments: 0,
                  );
                }
            );
          }
        },
      ),
    );
  }
}