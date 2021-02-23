import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  FirebaseUser currentUser;
  String name = "";
  String email = "";
  String url = "";

  Future<String> googleSingIn() async {
    final GoogleSignInAccount account = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await account.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    setState(() {
      email = user.email;
      url = user.photoUrl;
      name = user.displayName;
    });

    return '구글 로그인 성공: $user';
  }

  void googleSignOut() async {
    await _auth.signOut();
    await googleSignIn.signOut();

    setState(() {
      email = "";
      url = "";
      name = "";
    });

    print("User Sign Out");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            email == ""
                ? Container()
                : Column(
              children: <Widget>[
                Image.network(url),
                Text(name),
                Text(email),
              ],
            ),
            RaisedButton(
              onPressed: () {
                if (email == "") {
                  googleSingIn();
                } else {
                  googleSignOut();
                }
              },
              child: Container(
                  width: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(Icons.subdirectory_arrow_right),
                      Text(email == "" ? 'Google Login' : "Google Logout")
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}