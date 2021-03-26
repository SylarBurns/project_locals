import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:naver_map_plugin/naver_map_plugin.dart';
import 'package:project_locals/confidential.dart';
import 'package:project_locals/globals.dart' as globals;
class naverMap extends StatefulWidget {
  @override
  _naverMapState createState() => _naverMapState();
}

class _naverMapState extends State<naverMap> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Completer<NaverMapController> _controller = Completer();
  MapType _mapType = MapType.Basic;
  LocationTrackingMode _trackingMode = LocationTrackingMode.NoFollow;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body:Stack(
        children: <Widget>[
          NaverMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(36.08191576364081, 129.3974868521867),
              zoom: 17,
            ),
            onMapCreated: onMapCreated,
            mapType: _mapType,
            initLocationTrackingMode: _trackingMode,
            onMapLongTap: _onMapLongTap,
            rotationGestureEnable: false,
            scrollGestureEnable: false,
            tiltGestureEnable: false,
            zoomGestureEnable: false,
          ),
          _regionAuthenticator(),
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
      print("Area1: ${response.area1}\nArea2: ${response.area2}\nArea3: ${response.area3}");
      scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(
            '[onLongTap]lat: ${position.latitude}, lon: ${position.longitude}'),
        duration: Duration(milliseconds: 500),
        backgroundColor: Colors.black,
      ));
    });
  }
  _regionAuthenticator() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton.extended(
          onPressed: (){
            _onPressedTakeRegionInfo();
            },
          backgroundColor: Colors.white60,
          label: const Text('지역인증', style: TextStyle(color: Colors.black54),),
          icon: const Icon(Icons.my_location_sharp, color: Colors.black54,),
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
          title: Text("현재 지역을 확인하시고 확인을 눌러 지역인증을 완료해주세요"),
          content: SingleChildScrollView(child:Text("${info.area1} ${info.area2}")),
          actions: <Widget>[
            FlatButton(
              child: Text("취소"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("확인"),
              onPressed: () async {
                await globals.dbUser.userOnDB.updateData({
                  "region":info.area2
                }).then((value) async {
                  await globals.dbUser.getUserFromDB();
                  setState(() {});
                  Navigator.pop(context);
                  Navigator.pop(context);
                });
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