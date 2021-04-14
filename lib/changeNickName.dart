import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'globals.dart' as globals;

final db = Firestore.instance;

class ChangeNickName extends StatefulWidget {
  _ChangeNickNameState createState() => _ChangeNickNameState();
}

class _ChangeNickNameState extends State<ChangeNickName> {
  final _nicknameController = TextEditingController();
  String selectedNickname;
  String result = 'null';

  void searchNickname() async {
    if (_nicknameController.text.length < 2 ||
        _nicknameController.text.length >= 10) {
      result = 'unFit';
    } else {
      QuerySnapshot dbUser = await Firestore.instance
          .collection('user')
          .where('nickName', isEqualTo: _nicknameController.text)
          .getDocuments();
      if (dbUser.documents.isNotEmpty) {
        result = 'duplicate';
      } else {
        result = 'unique';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '닉네임 변경',
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () async {
              await searchNickname();
              if(result == 'null') _showDialog('닉네임을 입력하세요');
              else if(result == 'unFit') _showDialog("2~10 글자, 한글 및 영어 사용가능");
              else if(result == 'duplicate') _showDialog("닉네임이 이미 존재합니다");
              else {
                globals.dbUser.setNickName(_nicknameController.text);

                await db.collection('user').document(globals.dbUser.getUID()).updateData({
                  'nickName': _nicknameController.text,
                  'lastModified': DateTime.now(),
                });

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(25, 10, 25, 5),
            alignment: Alignment.center,
            height: 50,
            child: Text(
              '현재 닉네임 : ' + globals.dbUser.getNickName(),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(25, 10, 25, 5),
            alignment: Alignment.center,
            height: 50,
            child: TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '닉네임',
              ),
              controller: _nicknameController,
            ),
          ),
        ],
      ),
    );
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