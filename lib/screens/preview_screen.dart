import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:faceid_mobile/utils/utils.dart' as Utils;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'confirmation_page.dart';

class PreviewImageScreen extends StatefulWidget {
  final List<String> imagePaths;

  PreviewImageScreen({this.imagePaths});

  @override
  _PreviewImageScreenState createState() => _PreviewImageScreenState();
}

class _PreviewImageScreenState extends State<PreviewImageScreen> {
  CancelableOperation<http.StreamedResponse> cancellableOperation;

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
                _showWaitingDialog(context);
                var res = await _shareImages();
                print(res);
                if (res == null || res.containsKey('error')) {
                  Navigator.pop(context);
                  Utils.showErrorDialog(
                      context, res != null ? res['error'] : "Couldn't connect to the server !", () {});
                } else if (res.containsKey('uploaded_images')) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ConfirmationScreen(
                                response: res,
                              )),
                      (Route<dynamic> route) => false);
                }
              },
              child: Icon(
                Icons.cloud_upload,
                size: 26.0,
              ),
            ),
          )
        ],
        backgroundColor: Colors.orange,
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
    var emulatorUrl = "http://10.0.2.2:5000/";
    var onDevice = "http://192.168.1.103:5000/";
    var errorIp = "http://1968.1.102:5000/";
    var request = http.MultipartRequest('POST', Uri.parse(errorIp + 'upload_images'));
    // Todo : Use the auth user
    request.fields['username'] = 'nait_cherif';
    print('len of paths ${widget.imagePaths.length}');
    for (var path in widget.imagePaths) {
      print('path $path');
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }
    try {
      cancellableOperation = CancelableOperation.fromFuture(
        request.send(),
        onCancel: () => {print('Canceled')},
      );
      var streamedResponse = await cancellableOperation.value;
      var response = await http.Response.fromStream(streamedResponse);
      Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } on SocketException catch (e) {
      print(e);
      return null;
    }
  }

  _showWaitingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new CupertinoActivityIndicator(
          radius: 15,
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 15),
          child: Text(
            'Processing!',
            style: TextStyle(fontSize: 18),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text("Cancel"),
            onPressed: () {
              cancellableOperation.cancel();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }
}
