import 'package:flutter/material.dart';

class homePage extends StatefulWidget{
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      children: [
        Text("인기글"),
        SizedBox(height: 10,),
        Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.60),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),

          ),
          child: Column(
            children: [
              Text("hot posts")
            ],
          ),
        ),
        SizedBox(height: 50,),
        Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black.withOpacity(0.60),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12)
        ),
          child: Column(
            children: [

            ],
          ),
        ),

      ]
    );
  }
}