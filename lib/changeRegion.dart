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
  int _selectedRegion = -1;

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

            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: db.collection('area1').getDocuments(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) return Container();

          List<DocumentSnapshot> documents = snapshot.data.documents;
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width/2 - 3,
                child: ListView(
                  children: documents.map((area1) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(area1.documentID),
                          onTap: () {
                            _selectedRegion = documents.indexOf(area1);
                            setState(() {});
                          },
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
                child: _selectedRegion == -1 ?
                    Center(child: Text('지역을 선택하세요'),)
                    : _buildArea2(context, documents[_selectedRegion])
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArea2(BuildContext context, DocumentSnapshot area1) {
    List area2 = area1['area2'];

    return ListView(
      children: area2.map((region) {
        return Column(
          children: [
            ListTile(
              title: Text(region),
            ),
            Divider(),
          ],
        );
      }).toList(),
    );
  }
}