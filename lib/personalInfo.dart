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
import 'package:google_sign_in/google_sign_in.dart';
import 'changeRegion.dart';

final db = Firestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

class personalInfo extends StatefulWidget{
  final Function refresh;

  personalInfo({Key key, this.refresh}) : super(key: key);
  @override
  personalInfoState createState() => personalInfoState();

}
class personalInfoState extends State<personalInfo>{
  Refresh(){setState(() {});}
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
              onPressed:() => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeRegion(),
                  )
              ).then((value) {
                setState(() {});
                widget.refresh();
              }),
              child: Text(
                  "지역 변경"
              ),
            ),
            FlatButton(
              onPressed:() async {
                await _auth.signOut().then((value) async {
                  await _googleSignIn.signOut().then((value){
                    Navigator.pushReplacementNamed(context, '/');
                  });
                });
              },
              child: Text(
                  "로그아웃"
              ),
            ),
          ],
        ),
      ),
    );
  }
}