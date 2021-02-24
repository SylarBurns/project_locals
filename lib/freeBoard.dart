import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(padding: EdgeInsets.only(bottom: 2.0)),
              Text(
                '$content',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '10 min ago',
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.black45,
                ),
              ),
              Padding(padding: EdgeInsets.only(right: 1.0)),
              Text(
                '$writer',
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ],
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
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(2.0),
            child: ListTile(
              title: Text(
                'Hello Everyone!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'content',
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
                        'user123',
                        style: TextStyle(
                          color: Colors.black45,
                        ),
                      ),
                      Padding(padding: EdgeInsets.only(right: 185.0)),
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 15.0,
                      ),
                      Padding(padding: EdgeInsets.only(right: 2.0)),
                      Text(
                        '0',
                      ),
                      Padding(padding: EdgeInsets.only(right: 10.0)),
                      Icon(
                        Icons.comment_bank_outlined,
                        size: 15.0,
                      ),
                      Padding(padding: EdgeInsets.only(right: 2.0)),
                      Text(
                        '0'
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}