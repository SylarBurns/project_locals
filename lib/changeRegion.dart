import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'globals.dart' as globals;

final db = Firestore.instance;

class ChangeRegion extends StatefulWidget {

  _ChangeRegionState createState() => _ChangeRegionState();
}

class _ChangeRegionState extends State<ChangeRegion> {
  String _selectedArea1 = 'null';
  String _selectedArea2 = 'null';
  int _selectedIndex;
  QuerySnapshot qSnap;
  List<DocumentSnapshot> docList;

  void initState() {
    super.initState();
    loadData();
  }

  void dispose() {
    super.dispose();
  }

  void loadData() async {
    qSnap = await db.collection('area1').getDocuments();
    docList = qSnap.documents;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          '지역 변경',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () {
              globals.dbUser.setSelectedRegion(_selectedArea2);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: docList == null ?
          Center(child: CircularProgressIndicator(),)
          : Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width/2 - 3,
            child: ListView(
              children: docList.map((area1) {
                return Column(
                  children: [
                    Container(
                      child: ListTile(
                        title: Text(area1.documentID),
                        onTap: () {
                          _selectedArea1 = area1.documentID;
                          _selectedIndex = docList.indexOf(area1);
                          _selectedArea2 = 'null';
                          setState(() {});
                        },
                      ),
                      color: area1.documentID == _selectedArea1 ? Colors.black12 : Colors.white12,
                    ),
                    Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
          VerticalDivider(width: 4,),
          Container(
              width: MediaQuery.of(context).size.width/2 - 2,
              child: _selectedArea1 == 'null' ?
              Center(child: Text('지역을 선택하세요'),)
                  : _buildArea2(context, docList[_selectedIndex])
          ),
        ],
      ),
    );
  }

  Widget _buildArea2(BuildContext context, DocumentSnapshot area1) {
    List area2 = area1['area2'];

    return ListView(
      children: area2.map((region) {
        // int index = area2.indexOf(region);
        return Column(
          children: [
            Container(
              child: ListTile(
                title: Text(region),
                onTap: () {
                  _selectedArea2 = region;
                  setState(() {});
                },
              ),
              color: region == _selectedArea2 ? Colors.black12 : Colors.white12,
            ),
            Divider(),
          ],
        );
      }).toList(),
    );
  }
}