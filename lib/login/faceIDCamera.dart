import 'dart:convert';
import 'dart:io';
import 'package:faceid_mobile/login/home_page.dart';
import 'package:faceid_mobile/login/login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:toast/toast.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as ImageLib;
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class FaceIDCamera extends StatefulWidget {
  @override
  _FaceIDCameraState createState() => _FaceIDCameraState();
}

class _FaceIDCameraState extends State<FaceIDCamera> {
  final storage = FlutterSecureStorage();

  List<CameraDescription> cameras;
  CameraController cameraController;
  var username = '';
  var userImagePath;
  var processing = true;
  var nbrEssai = 3;

  Future<Map<String, dynamic>> _uploadImage() async {
    String url = 'http://10.0.0.2:5000/facial_recognition';
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );
    request.files.add(await http.MultipartFile.fromPath('file', userImagePath));
    print('ready to send request ...');
    var streamedResponse = await request.send();
    print('request is sent ...');
    var response = await http.Response.fromStream(streamedResponse);
    Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  }

  Future<void> _getImageAndDetectFaces(
      String path, BuildContext context) async {
    final image = FirebaseVisionImage.fromFilePath(path);
    final faceDetector = FirebaseVision.instance
        .faceDetector(FaceDetectorOptions(enableClassification: true));
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      if (faces.length > 0) {
        if (faces.length > 1) {
          setState(() {
            print("There is more than 1 face !");
          });
        } else {
          _cropAndSaveImage(path, faces[0]);
        }
      } else {
        setState(() {
          print("The image doesn't contain any face !");
        });
      }
    }
  }

  void _cropAndSaveImage(String path, Face face) {
    int trashHold = 20;
    ImageLib.Image image = ImageLib.decodeImage(File(path).readAsBytesSync());
    print(
        "f ${face.boundingBox.topLeft.dy} ${face.boundingBox.topLeft.dx} ${face.boundingBox.width} ${face.boundingBox.height}");
    ImageLib.Image copy = ImageLib.copyRotate(
        ImageLib.copyCrop(
            image,
            face.boundingBox.topLeft.dy.toInt(),
            face.boundingBox.topLeft.dx.toInt(),
            face.boundingBox.width.toInt(),
            face.boundingBox.height.toInt()),
        -90);

    // Save the thumbnail as a PNG.
    File(path)..writeAsBytesSync(ImageLib.encodePng(copy));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      cameraController = CameraController(cameras[1], ResolutionPreset.medium);
      cameraController.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Widget _showDialog(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        //Center Row contents horizontally,
        crossAxisAlignment: CrossAxisAlignment.center,
        //Center Row contents vertically,
        children: [
          Text('Nombre de tentatives est expirés !'),
        ],
      ),
      actions: [
        FlatButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white),
          ),
          color: Colors.orange,
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: (cameraController != null)
          ? (nbrEssai > 0)
              ? Column(
                  children: [
                    (userImagePath == null)
                        ? AspectRatio(
                            aspectRatio: cameraController.value.aspectRatio,
                            child: CameraPreview(cameraController),
                          )
                        : Image.file(File(userImagePath)),
                    SizedBox(
                      height: 20,
                    ),
                    FloatingActionButton(
                      child: processing
                          ? Icon(
                              Icons.camera,
                              color: Colors.white,
                            )
                          : CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange,
                              ),
                            ),
                      backgroundColor: Colors.black,
                      onPressed: () async {
                        try {
                          // Construct the path where the image should be saved using the path package.
                          DateTime now = DateTime.now();
                          String formattedDate =
                              DateFormat('yyyy_MM_dd_HH_mm_ss').format(now);
                          final path = join(
                            (await getTemporaryDirectory()).path,
                            '$formattedDate.png',
                          );
                          // Attempt to take a picture and log where it's been saved.
                          await cameraController.takePicture(path);
                          setState(() {
                            processing = false;
                          });
                          setState(() {
                            userImagePath = path;
                            print(path);
                          });
                          await _getImageAndDetectFaces(path, context);
                          var res = await _uploadImage();
                          print('Res : $res');
                          setState(() {
                            if (res['response'] != null) {
                              username = res['response'][0]['username'];
                              print('Hello $username');
                              storage.write(key: "username", value: username);
                              // TODO : decode JwtTocken and store it to the secureStorage
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(username),
                                ),
                              );
                            } else {
                              processing = true;
                              userImagePath = null;
                              nbrEssai--;
                              if (nbrEssai != 0)
                                Toast.show(
                                  "Authentication failed, try again !",
                                  context,
                                  duration: Toast.LENGTH_LONG,
                                  gravity: Toast.CENTER,
                                );
                            }
                          });
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text('$nbrEssai tentative(s) restées'),
                  ],
                )
              : _showDialog(context)
          : Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange,
                ),
              ),
            ),
    );
  }
}
