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
    QuerySnapshot dbUser = await Firestore.instance
        .collection('user')
        .where('nickName', isEqualTo: _nicknameController.text)
        .getDocuments();
    if (dbUser.documents.isNotEmpty) {
      result = await _showDuplicateDialog();
    } else {
      result = await _showUniqueDialog();
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
                  onPressed: (){
                    result = _nicknameController.text;
                    Navigator.pop(context);
                  },
                  child: Text("예", style: TextStyle(color: Theme.of(context).textTheme.bodyText1.color),)),
              FlatButton(
                  onPressed: () {
                    result = null;
                    Navigator.pop(context);
                  },
                  child: Text("아니오", style: TextStyle(color: Theme.of(context).textTheme.bodyText1.color),))
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 30),
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    height: 50,
                    width: 350,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nickname',
                        suffix: FlatButton(child: Text("중복 확인"), onPressed:() async {
                          selectedNickname = await searchNickname();
                        })
                      ),
                      controller: _nicknameController,
                    ),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    height: 50,
                    width: 350,
                    child: selectedRegion == null
                        ?Text("지역 인증을 해주세요")
                        :Text(selectedRegion)
                  ),
                  SizedBox(height: 10,),
                  RaisedButton(
                    child: Text("지역 인증하기"),
                    onPressed: ()async{
                      selectedRegion = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context)=>naverMap())
                      );
                      setState(() {});
                    },
                  ),
                  RaisedButton(
                    child: Text("확인"),
                    onPressed: ()async{
                      if(selectedNickname!=null && selectedRegion!=null){
                        final FirebaseUser currentUser = await _auth.currentUser();
                        await Firestore.instance
                            .collection('user')
                            .document(currentUser.uid)
                            .setData({
                          "nickName": selectedNickname,
                          "region": selectedRegion,
                          "postLikeList": [],
                          "commentLikeList": [],
                          "unreadCount":0,
                          "unreadNotification":0,
                        });
                        await getUser(currentUser);
                      }else{
                        showDialog(
                            context: context,
                            builder: (BuildContext context){
                              return AlertDialog(
                                title: Text("닉네임과 지역 정보를 입력하세요!"),
                                actions: [
                                  FlatButton(onPressed:()=>Navigator.pop(context), child: Text("확인"))
                                ],
                              );
                            }
                        );
                      }
                    }
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
