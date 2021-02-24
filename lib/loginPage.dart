import 'package:flutter/material.dart';

class loginPage extends StatefulWidget {
  @override
  _loginPageState createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Log in"),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('Log in'),
          onPressed: (){
            Navigator.pushNamed(context, '/homePage');
          },
        ),
      ),
    );
  }
}