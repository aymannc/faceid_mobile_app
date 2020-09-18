import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';
class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(),
    );
  }
}

void main(){
  runApp(CameraApp());
}

