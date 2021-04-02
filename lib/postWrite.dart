import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import 'dart:io';

import 'globals.dart' as globals;

class PostWrite extends StatefulWidget {
  final String boardType;

  PostWrite({Key key, @required this.boardType,});

  @override
  _PostWriteState createState() => _PostWriteState();
}

class _PostWriteState extends State<PostWrite> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  Future<PickedFile> imageFile;
  File _imageFile;

  pickImageFromGallery(ImageSource source) {
    setState(() {
      imageFile = imagePicker.getImage(source: source);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: Text(
          '글 쓰기',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
            ),
            onPressed: () async {
              var data = {
                'boardType': widget.boardType,
                'comments': 0,
                'content': contentController.text,
                'date': DateTime.now(),
                'isEdit': false,
                'like': 0,
                'region': globals.dbUser.getRegion(),
                'report': 0,
                'reportUserList': [],
                'title': titleController.text,
                'writer': globals.dbUser.getUID(),
              };
              if(_imageFile != null) {
                data['image'] = basename(_imageFile.path);
              }

              if(widget.boardType == 'anonymous') {
                String uid = globals.dbUser.getUID();
                data['writerNick'] = 'Anonymous';
                data['anonymousList'] = {'$uid': 'Anonymous(writer)'};
              }
              else {
                data['writerNick'] = globals.dbUser.getNickName();
              }
              await Firestore.instance.collection('board').add(data);
              await uploadImageToFirebase(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(15.0, 8.0, 15.0, 8.0),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Title',
                  ),
                ),
                SizedBox(height: 8.0,),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Content',
                  ),
                ),
                SizedBox(height: 30.0,),
                _showImage(context),
                SizedBox(height: 10,),
                Center(
                  child: RaisedButton(
                    child: Text("Select Image from Gallery"),
                    onPressed: () {
                      pickImageFromGallery(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _showImage(BuildContext context) {
    return FutureBuilder<PickedFile>(
      future: imageFile,
      builder: (BuildContext context, AsyncSnapshot<PickedFile> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          print(snapshot.data.path);
          _imageFile = File(snapshot.data.path);
          return Container(
            padding: EdgeInsets.fromLTRB(5, 3, 5, 3),
            child: Image.file(
              _imageFile,
              // width: 300,
              height: MediaQuery.of(context).size.height/4,
            ),
          );
        } else if (snapshot.error != null) {
          return const Text(
            'Error Picking Image',
            textAlign: TextAlign.center,
          );
        } else {
          return const Text(
            'No Image Selected',
            textAlign: TextAlign.center,
          );
        }
      },
    );
  }

  Future uploadImageToFirebase(BuildContext context) async {
    String fileName = basename(_imageFile.path);
    StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child('post/$fileName');
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(_imageFile);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    taskSnapshot.ref.getDownloadURL().then(
          (value) => print("Done: $value"),
    );
  }
}