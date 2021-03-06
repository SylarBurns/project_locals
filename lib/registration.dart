import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'globals.dart' as globals;
import 'package:project_locals/naver_map.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class registration extends StatefulWidget {
  @override
  _registrationState createState() => _registrationState();
}

class _registrationState extends State<registration> {
  final _nicknameController = TextEditingController();
  String selectedNickname;
  String selectedRegion;
  Future getUser(FirebaseUser currentUser) async {
    setState(() async {
      if (currentUser != null) {
        globals.dbUser = new globals.UserInfo(currentUser);
        await globals.dbUser.getUserFromDB();
        Navigator.pushReplacementNamed(context, '/homeNavigator');
      }
    });
  }

  Future searchNickname() async {
    String result;
    if (_nicknameController.text.length < 2 ||
        _nicknameController.text.length >= 10) {
      result = await _showUnfitDialog();
    } else {
      QuerySnapshot dbUser = await Firestore.instance
          .collection('user')
          .where('nickName', isEqualTo: _nicknameController.text)
          .getDocuments();
      if (dbUser.documents.isNotEmpty) {
        result = await _showDuplicateDialog();
      } else {
        result = await _showUniqueDialog();
      }
    }
    return result;
  }

  Future _showUniqueDialog() async {
    String result;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("사용 가능한 닉네임"),
            content: Text("등록 하시겠습니까?"),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    result = _nicknameController.text;
                    Navigator.pop(context);
                  },
                  child: Text(
                    "예",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color),
                  )),
              FlatButton(
                  onPressed: () {
                    result = null;
                    Navigator.pop(context);
                  },
                  child: Text(
                    "아니오",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color),
                  ))
            ],
          );
        });
    return result;
  }

  Future _showDuplicateDialog() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("중복된 닉네임"),
            content: Text(
              "다시 검색하세요",
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              new FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "닫기",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color),
                  ))
            ],
          );
        });
    return null;
  }

  Future _showUnfitDialog() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("닉네임 조건"),
            content: Text(
              "2~10 글자, 한글 및 영어 사용가능",
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              new FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "닫기",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color),
                  ))
            ],
          );
        });
    return null;
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
        child: Container(
            margin: EdgeInsets.fromLTRB(20, 30, 20, 30),
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: MediaQuery.of(context).size.width*0.8,
                  child: TextField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '닉네임',
                        suffix: FlatButton(
                            child: Text("중복 확인"),
                            onPressed: () async {
                              selectedNickname = await searchNickname();
                            })),
                    controller: _nicknameController,
                    minLines: 1,
                    maxLines: 1,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    width: 350,
                    child: selectedRegion == null
                        ? Text(
                            "지역 인증을 해주세요\n데이터 사용을 권장드립니다\n현 위치가 뜨지 않는다면 재시도해주세요",
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            selectedRegion,
                            textAlign: TextAlign.center,
                          )),
                Center(
                  widthFactor: 3,
                  child: Row(
                    children: [
                      Spacer(
                        flex: 1,
                      ),
                      RaisedButton(
                        child: Text("지역 인증하기"),
                        onPressed: () async {
                          selectedRegion = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => naverMap()));
                          setState(() {});
                        },
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      RaisedButton(
                          child: Text("확인"),
                          onPressed: () async {
                            if (selectedNickname != null &&
                                selectedRegion != null) {
                              final FirebaseUser currentUser =
                                  await _auth.currentUser();
                              await Firestore.instance
                                  .collection('user')
                                  .document(currentUser.uid)
                                  .setData({
                                "nickName": selectedNickname,
                                "region": selectedRegion,
                                "postLikeList": [],
                                "commentLikeList": [],
                                "unreadCount": 0,
                                "unreadNotification": 0,
                                "lastModified" : DateTime.now(),
                              });
                              await getUser(currentUser);
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("닉네임과 지역 정보를 입력하세요!"),
                                      actions: [
                                        FlatButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text("확인"))
                                      ],
                                    );
                                  });
                            }
                          }),
                      Spacer(
                        flex: 1,
                      ),
                    ],
                  ),
                )
              ],
            )),
      ),
    );
  }
}
