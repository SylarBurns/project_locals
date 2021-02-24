import 'package:flutter/material.dart';

class boardHome extends StatefulWidget {
  @override
  _boardHomeState createState() {
    return _boardHomeState();
  }
}

class _boardHomeState extends State<boardHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Project Locals')),
      body: Text("this should be Home Page"),
    );
  }
}