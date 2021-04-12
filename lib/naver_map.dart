import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:naver_map_plugin/naver_map_plugin.dart';
import 'package:project_locals/confidential.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_locals/globals.dart' as globals;
final db = Firestore.instance;
class naverMap extends StatefulWidget {
  @override
  _naverMapState createState() => _naverMapState();
}

class _naverMapState extends State<naverMap> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Completer<NaverMapController> _controller = Completer();
  MapType _mapType = MapType.Basic;
  LocationTrackingMode _trackingMode = LocationTrackingMode.Follow;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body:Stack(
        children: <Widget>[
          NaverMap(
            onMapCreated: onMapCreated,
            mapType: _mapType,
            initLocationTrackingMode: _trackingMode,
            onMapLongTap: _onMapLongTap,
            rotationGestureEnable: false,
            scrollGestureEnable: false,
            tiltGestureEnable: false,
            zoomGestureEnable: false,
          ),
          _regionAuthenticator(context),
        ],
      ),
    );
  }
  Future<regionInfo> fetchRegionInfo(LatLng position) async {
    confidentialInfo info = new confidentialInfo();
    final response = await http.get(
      Uri.encodeFull("https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?"+
          "request=coordsToaddr&coords=${position.longitude},${position.latitude}&sourcecrs=epsg:4326&output=json&orders=addr"),
      headers: {
        //Client ID
        "X-NCP-APIGW-API-KEY-ID": info.getNaverCID(),
        //Client Secrete
        "X-NCP-APIGW-API-KEY": info.getNaverCS(),
      },
    );
    if (response.statusCode == 200) {
      return regionInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load location Information');
    }
  }
  _onMapLongTap(LatLng position) async {
    await fetchRegionInfo(position).then((response){
      scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(
            '[onLongTap]lat: ${position.latitude}, lon: ${position.longitude}'),
        duration: Duration(milliseconds: 500),
        backgroundColor: Colors.black,
      ));
    });
  }
  _regionAuthenticator(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton.extended(
          onPressed: (){
            _onPressedTakeRegionInfo();
            },
          backgroundColor: Theme.of(context).buttonTheme.colorScheme.secondary,
          label: Text('지역인증', style: TextStyle(color:Theme.of(context).accentColor),),
          icon: Icon(Icons.my_location_sharp, color:Theme.of(context).accentColor,),
        ),
      )
    );
  }
  /// 지도 생성 완료시
  void onMapCreated(NaverMapController controller) {
    if (_controller.isCompleted) _controller = Completer();
    _controller.complete(controller);
  }
  /// 위치 파악
  void _onPressedTakeRegionInfo() async {
    final controller = await _controller.future;
    await controller.getCameraPosition().then((position) async{
      await fetchRegionInfo(position.target).then((info)async{
        // await _showDialog(info).then((value){Navigator.pop(context);});
        _showDialog(info);
      });
    });
  }
  void _showDialog(regionInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0)
          ),
          title: Text("확인을 눌러 지역인증을 완료해주세요", style: TextStyle(fontSize: 18),),
          content: Container(height: 20, alignment:Alignment.center,child:Text("${info.area1} ${info.area2}")),
          actions: <Widget>[
            FlatButton(
              child: Text("취소", style: Theme.of(context).textTheme.button,),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("확인", style: Theme.of(context).textTheme.button),
              onPressed: () async {
                await db.collection("area1").document(info.area1).get().then((document) async {
                  if(document.exists){
                    if(document["area2"].contains(info.area2)){
                    }else{
                      await db.runTransaction((transaction) async {
                        final freshSnapshot = await transaction.get(document.reference);
                        final fresh = freshSnapshot.data;
                        List<dynamic> area2List = fresh["area2"];
                        if (!area2List.contains(info.area2)) {
                          area2List.add(info.area2);
                        }
                        await transaction.update(document.reference, {
                          'area2': area2List,
                        });
                      });
                    }
                  }else{
                    await db.collection('area1').document(info.area1).setData(
                      {
                        "area2":[info.area2]
                      }
                    );
                  }
                });
                Navigator.pop(context);
                Navigator.pop(context, info.area2);
              }
            )
          ],
        );
      },
    );
  }
}
class regionInfo {
  final area1;
  final area2;
  final area3;
  regionInfo({@required this.area1, @required this.area2, @required this.area3});
  factory regionInfo.fromJson(Map<String, dynamic> json) {
    return regionInfo(
        area1: json["results"][0]["region"]["area1"]["name"].toString(),
        area2: json["results"][0]["region"]["area2"]["name"].toString(),
        area3: json["results"][0]["region"]["area3"]["name"].toString()
    );
  }
}