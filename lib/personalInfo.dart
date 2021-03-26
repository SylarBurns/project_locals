import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'postView.dart';
import 'package:rxdart/rxdart.dart';
import 'package:project_locals/routes.dart';
import 'package:project_locals/naver_map.dart';
import 'globals.dart' as globals;

import 'changeRegion.dart';

final db = Firestore.instance;

class personalInfo extends StatefulWidget{
  @override
  personalInfoState createState() => personalInfoState();

}
class personalInfoState extends State<personalInfo>{
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: ListView(
          children: [
            FlatButton(
                onPressed:()=>Navigator.pushNamed(context, '/likedList'),
                child: Text(
                      "내가 좋아요 누른 게시물"
                      ),
            ),
            FlatButton(
                onPressed:()=>Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => naverMap(),
                    )
                ),
                child: Text(
                  "네이버 지도"
                )
            ),
            FlatButton(
              onPressed:() => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeRegion(),
                  )
              ),
              child: Text(
                  "지역 변경"
              ),
            ),
          ],
        ),
      ),
    );
  }
}