import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

showErrorDialog(BuildContext context, String error, Function callback) {
  showDialog(
    context: context,
    builder: (BuildContext context) => new CupertinoAlertDialog(
      title: new Text(
        error,
        style: TextStyle(color: Colors.red),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: new Text("Close"),
          onPressed: () {
            callback();
            Navigator.of(context).pop();
          },
        )
      ],
    ),
  );
}
