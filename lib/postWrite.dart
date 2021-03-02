import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostWrite extends StatefulWidget {
  final String boardType;


  PostWrite({Key key, @required this.boardType,});

  @override
  _PostWriteState createState() => _PostWriteState();
}

class _PostWriteState extends State<PostWrite> {

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}