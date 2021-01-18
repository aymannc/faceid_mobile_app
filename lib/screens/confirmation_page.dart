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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Spacer(),
              Container(
                child: MaterialButton(
                  shape: CircleBorder(side: BorderSide(width: 2, color: Colors.green)),
                  child: Icon(
                    Icons.done,
                    size: 150,
                    color: Colors.green,
                  ),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  },
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Successfully uploaded the images !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30),
                ),
              ),
              Spacer(),
              RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), side: BorderSide(color: Colors.black)),
                onPressed: () {},
                color: Colors.black,
                textColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text("go to home page".toUpperCase(), style: TextStyle(fontSize: 20)),
                ),
              ),
              Spacer()
            ],
          ),
        ),
      ),
    );
  }
}
