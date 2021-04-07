import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'globals.dart' as globals;

class PostEdit extends StatefulWidget {
  final DocumentSnapshot post;

  PostEdit({Key key, @required this.post,});

  @override
  _PostEditState createState() => _PostEditState(key: this.key, post: this.post,);
}

class _PostEditState extends State<PostEdit> {
  DocumentSnapshot post;

  _PostEditState({Key key, this.post,});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: post['title']);
    final contentController = TextEditingController(text: post['content']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '글 수정',
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () async {
              await post.reference.updateData({
                'content': contentController.text,
                'isEdit': true,
                'title': titleController.text,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(15.0, 8.0, 15.0, 8.0),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8.0,),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}