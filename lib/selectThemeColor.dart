import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:project_locals/colors.dart';
import 'package:project_locals/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class selectThemeColor extends StatefulWidget {
  @override
  _selectThemeColorState createState() => _selectThemeColorState();
}

class _selectThemeColorState extends State<selectThemeColor> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("테마 색 설정"),
        ),
        body: ListView.builder(
            itemExtent: 200,
            itemCount: themeDataList.length,
            itemBuilder: (context, index) =>
                buildColorListItem(context, index)));
  }

  Widget buildColorListItem(BuildContext context, int index) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          onTap: () async {
            _showDialog(index);
          },
          child: colorRow(context, index, 8.0),
        ));
  }

  Widget colorRow(BuildContext context, int index, double paddingInbetween) {
    double boxheight = 200;
    return Card(
      color: themeDataList[index].background,
      elevation: 5,
      child: Row(
        children: [
          colorBlock(themeDataList[index].accent, boxheight, paddingInbetween),
          colorBlock(themeDataList[index].primary, boxheight, paddingInbetween),
          colorBlock(
              themeDataList[index].secondary, boxheight, paddingInbetween),
          colorBlock(themeDataList[index].backgroundSecondary, boxheight,
              paddingInbetween),
        ],
      ),
    );
  }

  Widget colorBlock(
      Color blockColor, double boxheight, double paddingInbetween) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(paddingInbetween),
        child: Card(
          elevation: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            child: Container(
              height: boxheight,
              decoration: BoxDecoration(
                color: blockColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDialog(int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          title: Text(
            "선택하신 색으로 테마를 바꾸시겠습니까?\n앱이 다시 시작됩니다",
            style: TextStyle(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
              height: MediaQuery.of(context).size.height * 0.2,
              child: colorRow(context, index, 4.0)),
          actions: <Widget>[
            FlatButton(
              child: Text(
                "취소",
                style: Theme.of(context).textTheme.button,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text(
                "확인",
                style: Theme.of(context).textTheme.button,
              ),
              onPressed: () async {
                await SharedPreferences.getInstance().then((preference) {
                  setState(() {
                    preference.setInt("ThemeIndex", index);
                  });
                  Phoenix.rebirth(context);
                });
              },
            )
          ],
        );
      },
    );
  }
}
