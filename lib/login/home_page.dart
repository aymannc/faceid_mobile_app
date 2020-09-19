import 'package:faceid_mobile/login/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatelessWidget {
  final String username;
  final storage = FlutterSecureStorage();

  HomePage(this.username);


  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("Home Page"),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Welcome $username"),
              SizedBox(
                height: 20,
              ),
              FlatButton(
                child: Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
                color: Colors.orange,
                onPressed: () {
                  storage.delete(key: 'username');
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WelcomePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}
