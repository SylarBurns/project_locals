import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';
import 'globals.dart' as globals;
import 'homeNavigator.dart' as home;

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

class loginPage extends StatefulWidget {
  @override
  _loginPageState createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
        child: ListView(
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            SizedBox(height: 80.0),
            _GoogleSignInSection(),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInSection extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _GoogleSignInSectionState();
}
class _GoogleSignInSectionState extends State<_GoogleSignInSection>{

  @override
  void initState(){
    autoLogin();
  }
  bool _success;
  String _userID;
  Future autoLogin() async {
    FirebaseUser currentUser = await _auth.currentUser();
    if(currentUser!=null){
      DocumentSnapshot dbUser = await Firestore.instance.collection('user').document(currentUser.uid).get();
      if(dbUser.exists){
        await getUser(currentUser);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(0,16.0,0,8.0),
          alignment: Alignment.center,
          child: RaisedButton(
            onPressed: () async {
              _signInWithGoogle();
              setState(() {
                if(_success!=null){
                  if(_success){
                    print("login success");
                  }
                }
              });
            },
            child: const Text('Google'),
          ),
        ),
      ],
    );
  }

  void _signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);
    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
    setState(() {
      if (user != null) {
        _success = true;
        _userID = user.uid;
        if(_success){
          handleGoogleSignIn(currentUser);
        }
      } else {
        _success = false;
      }
    });
  }
  Future handleGoogleSignIn(FirebaseUser currentUser) async {
    DocumentSnapshot dbUser = await Firestore.instance.collection('user').document(_userID).get();
    if(!dbUser.exists){
      Navigator.pushNamed(context, '/registration');
    }else{
      await getUser(currentUser);
      print("User with ID "+dbUser.documentID+" is in the DB\n");
    }
  }
  Future getUser(FirebaseUser currentUser) async {
    if(currentUser != null){
      globals.dbUser = new globals.UserInfo(currentUser);
      await globals.dbUser.getUserFromDB().then((value){
        Navigator.pushReplacementNamed(context, '/homeNavigator');
      });
    }
    setState((){});
  }
}