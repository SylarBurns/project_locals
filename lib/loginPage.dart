import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:loading_animations/loading_animations.dart';
import 'routes.dart';
import 'globals.dart' as globals;
import 'homeNavigator.dart' as home;
import 'ad_manager.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();
class loginPage extends StatefulWidget {
  @override
  _loginPageState createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF6ED),
      body: SafeArea(
        child: Column(
          children: [
            Spacer(flex: 1,),
            Center(child: Image.asset('assets/image/logo2.png')),
            Center(child: _GoogleSignInSection(),),
            Spacer(flex: 2,),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends State<_GoogleSignInSection> {
  bool loginStarted;
  bool _success;
  String _userID;
  @override
  void initState() {
    super.initState();
    loginStarted = false;
    autoLogin();
    _initAdMob();
    _initGoogleMobileAds();
  }
  Future autoLogin() async {
    setState(() {
      loginStarted = true;
    });
    FirebaseUser currentUser = await _auth.currentUser();
    if (currentUser != null) {
      DocumentSnapshot dbUser = await Firestore.instance
          .collection('user')
          .document(currentUser.uid)
          .get();
      if (dbUser.exists) {
        await getUser(currentUser);
      }
    } else {
      setState(() {
        loginStarted = false;
      });
    }
  }

  Future<void> _initAdMob() {
    return FirebaseAdMob.instance.initialize(appId: AdManager.appId);
  }

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        loginStarted
            ? Center(
                child: LoadingBouncingGrid.square(
                inverted: true,
                backgroundColor: Theme.of(context).primaryColor,
              ))
            : Container(
                padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 8.0),
                alignment: Alignment.center,
                child: RaisedButton(
                  color: Color(0xFFF6BF4F),
                  onPressed: () async {
                    setState(() {
                      loginStarted = true;
                    });
                    await _signInWithGoogle();
                    setState(() {
                      if (_success != null) {
                        if (_success) {
                          print("login success");
                        }
                      }
                    });
                  },
                  child: const Text('Google', style: TextStyle(color: Color(0xFFFAF6ED)),),
                ),
              ),
      ],
    );
  }

  Future _signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    if(googleUser!=null){
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
          if (_success) {
            handleGoogleSignIn(currentUser);
          }
        } else {
          _success = false;
        }
      });
    }else{
      setState(() {
        loginStarted = false;
      });
    }

  }

  Future handleGoogleSignIn(FirebaseUser currentUser) async {
    DocumentSnapshot dbUser =
        await Firestore.instance.collection('user').document(_userID).get();
    if (!dbUser.exists) {
      Navigator.pushNamed(context, '/registration');
    } else {
      await getUser(currentUser);
      print("User with ID " + dbUser.documentID + " is in the DB\n");
    }
  }

  Future getUser(FirebaseUser currentUser) async {
    if (currentUser != null) {
      globals.dbUser = new globals.UserInfo(currentUser);
      await globals.dbUser.getUserFromDB().then((value) {
        Navigator.pushReplacementNamed(context, '/homeNavigator');
      });
    }
    setState(() {});
  }
}
