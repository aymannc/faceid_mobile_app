import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class PreviewImageScreen extends StatefulWidget {
  final List<String> imagePaths;

  PreviewImageScreen({this.imagePaths});

  @override
  _PreviewImageScreenState createState() => _PreviewImageScreenState();
}

class _PreviewImageScreenState extends State<PreviewImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview'),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () async {

                // Todo : Show a spinner

                var res = await _shareImages();
                if (res.containsKey('error')) {
                  print(res['error']);
                  Fluttertoast.showToast(
                      msg: "Error !",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0);
                } else if (res.containsKey('uploaded_images')) {
                  // Todo : Go to Home page or something
                  Fluttertoast.showToast(
                      msg: "Successful ✔",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                      fontSize: 16.0);
                }
              },
              child: Icon(
                Icons.cloud_upload,
                size: 26.0,
              ),
            ),
          )
        ],
        backgroundColor: Colors.black,
      ),
      body: GridView.count(
        crossAxisCount: 3,
        // Generate 100 widgets that display their index in the List.
        children: List.generate(widget.imagePaths.length, (index) {
          return Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Image.file(
              File(widget.imagePaths[index]),
              fit: BoxFit.scaleDown,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
            margin: EdgeInsets.all(10),
          );
          // return Center(
          //   child: ),
          // );
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> _shareImages() async {
    var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/upload_images'));
    request.fields['username'] = 'nait_cherif';
    for (var path in widget.imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }
    final streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    Map<String, dynamic> responseData = jsonDecode(response.body);
    // try {
    //   // code that might throw an exception
    // }
    // on Key {
    //   // code for handling exception
    // }
    // responseData.keys

    return responseData;
  }
}
