import 'dart:io';

import 'package:camera/camera.dart';
import 'package:faceid_mobile/screens/preview_screen.dart';
import 'package:faceid_mobile/utils/utils.dart' as Utils;
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as ImageLib;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() {
    return _CameraScreenState();
  }
}

enum Status { RIGHT, LEFT, SMILE, NEUTRAL, EYES_CLOSED, GLASSES }

class _CameraScreenState extends State {
  // This class is responsible for establishing a connection to the device’s camera.

  CameraController controller;
  List cameras;
  int selectedCameraIdx;
  Map<Status, String> imagePaths = new Map<Status, String>();
  bool isProcessing = false;
  String error;
  Status currentStatus = Status.NEUTRAL;

  //
  Set<Status> listOfStatus = Set.of([Status.NEUTRAL]);

  // Set<Status> listOfStatus = Set.of(Status.values);

  @override
  void initState() {
    super.initState();
    // listOfStatus.addAll(Status.values);
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

    controller = CameraController(cameraDescription, ResolutionPreset.high, enableAudio: false);

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
    // Todo : make the bottom buttons transparent and stacked on the camera preview
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
                backgroundColor: Colors.orange,
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
            error = "There is more than 1 face !";
          });
        } else {
          _processFace(context, path, faces[0]);
        }
      } else {
        setState(() {
          isProcessing = false;
          error = "The image doesn't contain any face !";
        });
      }
      if (error != null) {
        Utils.showErrorDialog(context, error, () => _resetState());
      } else {
        _showSuccessfulToast();
      }
    }
  }

  void _onSwitchCamera() {
    selectedCameraIdx = selectedCameraIdx < cameras.length - 1 ? selectedCameraIdx + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    _initCameraController(selectedCamera);
  }

  void _onCapturePressed(BuildContext context) async {
    _resetState(processing: true);
    try {
      final path = join(
        // store the picture in the temp directory.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      ); //
      await controller.takePicture(path);
      _getImageAndDetectFaces(path, context);
    } catch (e) {
      print(e);
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error: ${e.code}\nError Message: ${e.description}';
    print(errorText);

    print('Error: ${e.code}\n${e.description}');
  }

  void _showSuccessfulToast() {
    Fluttertoast.showToast(
        msg: "Successful ✔",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void _showTheModal(BuildContext context) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(leading: Container(), middle: Text('Edit taken images')),
          child: SafeArea(
            bottom: false,
            child: ListView.builder(
                controller: ModalScrollController.of(context),
                itemCount: imagePaths.length,
                itemExtent: 100.0,
                itemBuilder: (BuildContext context, int index) {
                  Status key = imagePaths.keys.elementAt(index);
                  String label = key.toString().split('.')[1].replaceAll('_', ' ').toLowerCase();
                  return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: ListTile(
                        leading: Image.file(File(imagePaths[key])),
                        title: Text(label[0].toUpperCase() + label.substring(1)),
                        trailing: FlatButton(
                          child: Text(
                            "Remove",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            imagePaths.remove(key);
                            listOfStatus.add(key);
                            currentStatus = listOfStatus.first;
                            Navigator.of(context).pop();
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
        return "Give us a smile 😀";
      case Status.RIGHT:
        return "Look right ➡";
      case Status.LEFT:
        return "Look left ⬅";
      case Status.NEUTRAL:
        return "Try to be neutral 🙂";
      case Status.EYES_CLOSED:
        return "Now close your eyes ";
      case Status.GLASSES:
        return "Now put/remove glasses 👓 ";
      default:
        return "All done for now ✅";
    }
  }

  void _processFace(BuildContext context, String path, Face face) {
    {
      setState(() {
        isProcessing = false;
      });
      print("currentStatus " + currentStatus.toString());
      switch (currentStatus) {
        case Status.SMILE:
          {
            print('[smilingProbability] ' + face.smilingProbability.toString());
            if (face.smilingProbability < 0.80) {
              setState(() {
                error = "You're not smiling  😊";
              });
            }
          }
          break;
        case Status.NEUTRAL:
          {
            if (face.smilingProbability > 0.30) {
              setState(() {
                error = "Try not to laugh ! 🙂";
              });
            }
            print('[smilingProbability] ' + face.smilingProbability.toString());
            break;
          }
        case Status.RIGHT:
          {
            if (face.headEulerAngleY < 15) {
              setState(() {
                error = "Look at your right ! ➡";
              });
            }
            print('[headEulerAngleY] ' + face.headEulerAngleY.toString());
            break;
          }
        case Status.LEFT:
          {
            if (face.headEulerAngleY > -15) {
              setState(() {
                error = "Look at your left ⬅ !";
              });
            }
            print('[headEulerAngleY] ' + face.headEulerAngleY.toString());
            break;
          }
        case Status.EYES_CLOSED:
          {
            if (face.leftEyeOpenProbability > 0.1 || face.rightEyeOpenProbability > 0.1) {
              setState(() {
                error = "Close your eyes !";
              });
            }
            print('[leftEyeOpenProbability] ' + face.leftEyeOpenProbability.toString());
            print('[rightEyeOpenProbability] ' + face.rightEyeOpenProbability.toString());
            break;
          }
        case Status.GLASSES:
          {
            setState(() {
              isProcessing = false;
            });
            break;
          }
        default:
          {
            setState(() {
              isProcessing = false;
              error = "Current status is not valid";
            });
            break;
          }
      }
      if (error == null) {
        imagePaths[currentStatus] = path;
        _cropAndSaveImage(path, face);
        listOfStatus.remove(currentStatus);
        if (listOfStatus.isNotEmpty) {
          setState(() {
            currentStatus = listOfStatus.first;
          });
        } else {
          currentStatus = null;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewImageScreen(imagePaths: imagePaths.values.toList()),
            ),
          );
        }
      }
    }
  }

  void _resetState({processing = false}) {
    setState(() {
      isProcessing = processing;
      error = null;
    });
  }

  // The camera plugin produces images in landscape mode always, and for a photo taken in Portrait,
  // it sets hasOrientation true and orientation 6 in the EXIF header
  // https://github.com/brendan-duncan/image/issues/200#issuecomment-625481075
  void _cropAndSaveImage(String path, Face face) {
    final ImageLib.Image capturedImage = ImageLib.decodeImage(File(path).readAsBytesSync());
    print(" boundingBox "
        "${face.boundingBox.topLeft.dy} "
        "${face.boundingBox.topLeft.dx} "
        "${face.boundingBox.width} "
        "${face.boundingBox.height}");
    final ImageLib.Image copy = ImageLib.copyCrop(capturedImage, face.boundingBox.topLeft.dy.toInt(),
        face.boundingBox.topLeft.dx.toInt(), face.boundingBox.width.toInt(), face.boundingBox.height.toInt());
    final ImageLib.Image orientedImage = ImageLib.bakeOrientation(copy);
    File(path)..writeAsBytesSync(ImageLib.encodePng(orientedImage));
    print(path);
  }
}
