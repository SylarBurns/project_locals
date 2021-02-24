import 'package:flutter/material.dart';

import 'freeBoard.dart';

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
      appBar: AppBar(title: Text('Board')),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.push_pin_outlined),
            title: Text('Free Board'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FreeBoard()),
              );
            }
          ),
          ListTile(
            leading: Icon(Icons.push_pin_outlined),
            title: Text('Anonymous Board'),
          ),
          ListTile(
            leading: Icon(Icons.push_pin_outlined),
            title: Text('Promotion Board'),
          ),
        ],
      ),
    );
  }
}