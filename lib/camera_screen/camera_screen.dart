import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() {
    return _CameraScreenState();
  }
}

enum Status { RIGHT, LEFT, SMILE, NEUTRAL, EYES_CLOSED }

class _CameraScreenState extends State {
  // This class is responsible for establishing a connection to the device’s camera.

  CameraController controller;
  List cameras;
  int selectedCameraIdx;
  Map<Status, String> imagePaths = new Map<Status, String>();
  bool isProcessing = false;
  String successful;
  String error;
  Status currentStatus = Status.SMILE;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      availableCameras.forEach((element) {
        print(element.name);
      });
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraIdx = 1;
        });

        _initCameraController(cameras[selectedCameraIdx]).then((void v) {});
      } else {
        print("No camera available");
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.medium);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: _cameraPreviewWidget(),
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _cameraTogglesRowWidget(),
                  _captureControlRowWidget(context),
                  _showTakenPictures(context),
                ],
              ),
              SizedBox(height: 10.0)
            ],
          ),
        ),
      ),
    );
  }

  /// Display Camera preview.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      //
      child: Stack(
        children: <Widget>[
          CameraPreview(controller),
          Container(
            padding: EdgeInsets.only(top: 40),
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[Colors.black.withAlpha(0), Colors.black12, Colors.black54],
              ),
            ),
            child: Text(
              _getStatusLabel(),
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
          ),
        ],
      ),
    );
  }

  /// Display the control bar with buttons to take pictures
  Widget _captureControlRowWidget(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            FloatingActionButton(
                child: isProcessing
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Icon(Icons.camera),
                backgroundColor: Colors.black,
                onPressed: isProcessing
                    ? null
                    : () {
                        _onCapturePressed(context);
                      })
          ],
        ),
      ),
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;
    print('lensDirection' + lensDirection.toString());
    return Align(
      alignment: Alignment.centerLeft,
      child: FlatButton.icon(
          onPressed: _onSwitchCamera,
          icon: Icon(_getCameraLensIcon(lensDirection)),
          label: Text("${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1)}")),
    );
  }

  Widget _showTakenPictures(BuildContext context) {
    return Align(
        alignment: Alignment.centerLeft,
        child: FlatButton.icon(
          onPressed: () {
            _showTheModal(context);
          },
          icon: Icon(Icons.mode_edit),
          label: Text("Edit"),
        ));
  }

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  void _getImageAndDetectFaces(String path, BuildContext context) async {
    final image = FirebaseVisionImage.fromFilePath(path);
    final faceDetector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(enableClassification: true));
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      if (faces.length > 0) {
        if (faces.length > 1) {
          setState(() {
            isProcessing = false;
            error = "There is more than 1 face in this image !";
          });
        } else {
          Face face = faces[0];
          print('[leftEyeOpenProbability] ' + face.leftEyeOpenProbability.toString());
          print('[rightEyeOpenProbability] ' + face.rightEyeOpenProbability.toString());
          print('[headEulerAngleY] ' + face.headEulerAngleY.toString());
          print('[headEulerAngleZ] ' + face.headEulerAngleZ?.toString());
          print('[smilingProbability] ' + face.smilingProbability.toString());
          print('[FACE]' + face.boundingBox.toString());
          if (face.smilingProbability > 0.80) {
            setState(() {
              isProcessing = false;
              successful = "Katd7Ek al3frit yak";
            });
            imagePaths[Status.SMILE] = path;
            print('[PATH] path : ' + path);
          }
        }
      } else {
        setState(() {
          isProcessing = false;
          error = "The image doesn't contain any face !";
        });
      }
      _showDialog(context);
    }
    // TODO : Crop and save the image and add the path to the array

    // TODO : If all the pictures are taken in all positions upload to the server with the auth user
  }

  void _onSwitchCamera() {
    selectedCameraIdx = selectedCameraIdx < cameras.length - 1 ? selectedCameraIdx + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    _initCameraController(selectedCamera);
  }

  void _onCapturePressed(BuildContext context) async {
    setState(() {
      isProcessing = true;
      error = null;
      successful = null;
    });
    try {
      final path = join(
        // store the picture in the temp directory.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );
      await controller.takePicture(path);
      // TODO : Check for image conditions and positions
      _getImageAndDetectFaces(path, context);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => PreviewImageScreen(imagePath: path),
      //   ),
      // );
    } catch (e) {
      print(e);
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error: ${e.code}\nError Message: ${e.description}';
    print(errorText);

    print('Error: ${e.code}\n${e.description}');
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center, //Center Row contents horizontally,
              crossAxisAlignment: CrossAxisAlignment.center, //Center Row contents vertically,
              children: [
                isProcessing ? CircularProgressIndicator() : SizedBox.shrink(),
                successful != null ? Text(successful) : SizedBox.shrink(),
                error != null ? Text(error) : SizedBox.shrink(),
              ],
            ),
            actions: [
              FlatButton(
                child: Text("Done"),
                onPressed: isProcessing
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
              ),
            ],
          );
        });
      },
    );
  }

  void _showTheModal(BuildContext context) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context, scrollController) => Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(leading: Container(), middle: Text('Edit taken images')),
          child: SafeArea(
            bottom: false,
            child: ListView.builder(
                controller: scrollController,
                itemCount: imagePaths.length,
                itemExtent: 100.0,
                itemBuilder: (BuildContext context, int index) {
                  Status key = imagePaths.keys.elementAt(index);
                  return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: ListTile(
                        leading: Image.file(File(imagePaths[key])),
                        title: Text(key.toString().split('.')[1]),
                        trailing: FlatButton(
                          child: Text(
                            "Remove",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            imagePaths.remove(key);
                            if (imagePaths.isEmpty) Navigator.of(context).pop();
                          },
                        ),
                        contentPadding: EdgeInsets.all(16.0),
                      ));
                }),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    switch (currentStatus) {
      case Status.SMILE:
        return "Give us a smile 😊";
      case Status.RIGHT:
        return "Look right ➡";
      case Status.LEFT:
        return "Look left ⬅";
      case Status.NEUTRAL:
        return "Try to be neutral 😐";
      case Status.EYES_CLOSED:
        return "Now close your eyes 😑";
      default:
        return "Give us a big smile 😀";
    }
  }
}
