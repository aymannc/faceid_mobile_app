import 'package:flutter/material.dart';

class ConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> response;

  ConfirmationScreen({this.response});

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            children: <Widget>[
              Icon(Icons.done_all),
              Text('Done!'),
            ],
          ),
        ),
      ),
    );
  }
}
