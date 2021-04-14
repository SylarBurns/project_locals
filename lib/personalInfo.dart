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
import 'changeNickName.dart';

final db = Firestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

class personalInfo extends StatefulWidget {
  final Function refresh;

  personalInfo({Key key, this.refresh}) : super(key: key);
  @override
  personalInfoState createState() => personalInfoState();
}

class personalInfoState extends State<personalInfo> {
  int difference;

  Refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 15),
        child: ListView(
          children: [
            FlatButton(
              onPressed: () => Navigator.pushNamed(context, '/wroteList'),
              child: Text(
                "내가 쓴 글",
                style: TextStyle(
                    color: Theme.of(context).accentTextTheme.bodyText1.color),
              ),
            ),
            FlatButton(
              onPressed: () => Navigator.pushNamed(context, '/likedList'),
              child: Text(
                "좋아요 누른 글",
                style: TextStyle(
                    color: Theme.of(context).accentTextTheme.bodyText1.color),
              ),
            ),
            FlatButton(
              onPressed: () async {
                if(await _isChangeable()) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNickName(),
                      )).then((value) {
                    setState(() {});
                    widget.refresh();
                  });
                }
                else _showDialog(difference.toString() + '일 뒤에 변경하실 수 있습니다.');
              },
              child: Text(
                "닉네임 변경",
                style: TextStyle(
                    color: Theme.of(context).accentTextTheme.bodyText1.color),
              ),
            ),
            FlatButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeRegion(),
                  )).then((value) {
                setState(() {});
                widget.refresh();
              }),
              child: Text(
                "지역 변경",
                style: TextStyle(
                    color: Theme.of(context).accentTextTheme.bodyText1.color),
              ),
            ),
            FlatButton(
              onPressed: () async {
                await _auth.signOut().then((value) async {
                  await _googleSignIn.signOut().then((value) {
                    Navigator.pushReplacementNamed(context, '/');
                  });
                });
              },
              child: Text(
                "로그아웃",
                style: TextStyle(
                    color: Theme.of(context).accentTextTheme.bodyText1.color),
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.pushNamed(context, '/selectThemeColor');
              },
              child: Text(
                "테마 색 설정",
                style: TextStyle(
                    color: Theme.of(context).accentTextTheme.bodyText1.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _isChangeable() async {
    DocumentReference docRef = db.collection('user').document(globals.dbUser.getUID());
    DocumentSnapshot snapshot = await docRef.get();

    Timestamp tt = snapshot['lastModified'];
    DateTime dt = tt.toDate();

    if(DateTime.now().difference(dt) < Duration(days: 7)) {
      difference = 7 - DateTime.now().difference(dt).inDays;
      return false;
    }
    else return true;
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });

        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          content: SizedBox(
            width: 50,
            height: 30,
            child: Center(
              child: Text('$message'),
            ),
          ),
        );
      },
    );
  }
}
