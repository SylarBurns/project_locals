import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'globals.dart' as globals;

final FirebaseAuth _auth = FirebaseAuth.instance;

class registration extends StatefulWidget {
  @override
  _registrationState createState() => _registrationState();
}

class _registrationState extends State<registration> {
  final _nicknameController = TextEditingController();
  void _showDuplicateDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("중복된 닉네임"),
            content: Text("다시 검색하세요"),
            actions: <Widget>[
              new FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("닫기"))
            ],
          );
        });
  }

  Future getUser(FirebaseUser currentUser) async {
    setState(() async {
      if (currentUser != null) {
        globals.dbUser = new globals.UserInfo(currentUser);
        await globals.dbUser.getUserFromDB();
        Navigator.pushReplacementNamed(context, '/homeNavigator');
      }
    });
  }

  void _showUniqueDialog() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("사용 가능한 닉네임"),
            content: Text("등록 하시겠습니까?"),
            actions: <Widget>[
              FlatButton(
                  onPressed: () async {
                    final FirebaseUser currentUser = await _auth.currentUser();
                    await Firestore.instance
                        .collection('user')
                        .document(currentUser.uid)
                        .setData({
                      "nickName": _nicknameController.text,
                      "region": "포항시 북구",
                      "postLikeList": [],
                      "commentLikeList": [],
                    });
                    await getUser(currentUser);
                  },
                  child: Text("예")),
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("아니오"))
            ],
          );
        });
  }

  void searchNickname() async {
    QuerySnapshot dbUser = await Firestore.instance
        .collection('user')
        .where('nickName', isEqualTo: _nicknameController.text)
        .getDocuments();
    if (dbUser.documents.isNotEmpty) {
      _showDuplicateDialog();
    } else {
      _showUniqueDialog();
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 30),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 50,
                    width: 350,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nickname',
                        suffix: FlatButton(child: Text("중복 확인"), onPressed: searchNickname)
                      ),
                      controller: _nicknameController,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
