import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'postView.dart';
import 'package:rxdart/rxdart.dart';
import 'globals.dart' as globals;
final db = Firestore.instance;
class searchPage extends StatefulWidget{
  const searchPage({Key key}) : super(key: key);
  @override
  searchPageState createState() => searchPageState();
}

class searchPageState extends State<searchPage> {
  Refresh(){setState(() {});}
  static  TextEditingController _searchController;

  @override
  void initState() {
    _searchController = TextEditingController();
    super.initState();
  }
  void _clear() {
    _searchController.clear();
    setState((){});
  }
  @override
  void dispose() {
    _searchController?.dispose();
    _searchController = null;
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              child: AspectRatio(
                aspectRatio: 10/1.5,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "title, contents",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: _clear,
                    ),
                  ),
                  controller: _searchController,
                  onSubmitted:(data)=>updateSearchResult(),
                ),
              ),
            ),
            AspectRatio(
              aspectRatio: 10/12,
              child: searchResult(context),
            ),
          ],
        ),
      ),
    );
  }
  void updateSearchResult(){
    setState(() {});
  }
  Future getSearchResult() async{
    List<DocumentSnapshot> titleResults = (await db.collection('board')
        .where("region", isEqualTo: globals.dbUser.getSelectedRegion())
        .orderBy("date", descending: true)
        .getDocuments())
        .documents;
    List<DocumentSnapshot> result = new List<DocumentSnapshot>();
    titleResults.forEach((document) {
      if((document["title"].toString().toLowerCase()).contains(_searchController.text.toLowerCase())
          || (document["content"].toString().toLowerCase()).contains(_searchController.text)){
        result.add(document);
      }
    });
    return result;
  }
  Widget searchResult(BuildContext context){
    if(_searchController.text ==""){
      print("no result");
      return SizedBox(height: 10, width: 10,);
    }else{
      print("searching "+_searchController.text);
      return _searchedPost(context);
    }
  }
  Widget _searchedPost(BuildContext context) {
    return FutureBuilder(
      future: getSearchResult(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.none && snapshot.hasData == null){
          return SizedBox(height: 5, width: 5,);
        }else if(snapshot.data!=null && snapshot.data.length == 0){
          print("no result");
          return Center(child: Text("no result"));
        }else if(snapshot.data!=null){
            return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data.length,
              itemBuilder: (context, index){
                return _buildSearchedPostListItem(context, snapshot.data[index]);
              },
            );
          }else{
          return SizedBox(height: 5, width: 5,);
          }
        }
    );
  }

  Widget _buildSearchedPostListItem(
      BuildContext context, DocumentSnapshot document) {
    String title = document["title"];
    String writer = document["writerNick"];
    Timestamp tt = document["date"];
    DateTime dateTime =
    DateTime.fromMicrosecondsSinceEpoch(tt.microsecondsSinceEpoch);
    String date = DateFormat.Md().add_Hm().format(dateTime);
    int like = document["like"];
    int comments = document["comments"];
    String content = document["content"];
    String boardT = document["boardType"];
    String boardName = "";
    switch (boardT) {
      case "free":
        boardName = "자유 게시판";
        break;
      case "anonymous":
        boardName = "익명 게시판";
        break;
      case "lostAndFound":
        boardName = "Lost&Found";
        break;
    }
    return Container(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostView(postDocID: document.documentID,boardType: document["boardType"], boardName: boardName, writerUID: document['writer'],),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        Text('$writer',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text('$date',)
                ],
              ),
              Padding(padding: EdgeInsets.only(top: 3.0)),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$title',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.fromLTRB(0, 1, 0, 1),
                height: 30,
                child: Text(
                  '$content',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$boardName',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).accentColor.withOpacity(0.45)
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 15,
                            color: Theme.of(context).accentColor.withOpacity(0.45),
                          ),
                          Padding(padding: EdgeInsets.only(right: 2.0)),
                          Text(
                            '$like',
                            style:
                            TextStyle(color: Theme.of(context).accentColor.withOpacity(0.45)),
                          ),
                          Padding(padding: EdgeInsets.only(right: 10.0)),
                          Icon(
                              Icons.comment_bank_outlined,
                              size: 15.0,
                              color: Theme.of(context).accentColor.withOpacity(0.45)
                          ),
                          Padding(padding: EdgeInsets.only(right: 2.0)),
                          Text(
                            '$comments',
                            style: TextStyle(color: Theme.of(context).accentColor.withOpacity(0.45)),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}