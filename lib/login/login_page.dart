import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'file:///C:/Users/hp/Desktop/faceid_mobile_app/lib/login/home_page.dart';

const SERVER_IP = 'http://10.0.0.2:8083';
final storage = FlutterSecureStorage();

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  var loginPressed = false;

  void displayDialog(context, title, text) => showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(title: Text(title), content: Text(text)),
      );

  Future<bool> attemptLogIn(String username, String password) async {
    var res = await http.post("$SERVER_IP/login",
        body: jsonEncode(
            <String, String>{'username': username, 'password': password}));
    print("[res] : " + res.headers['authorization']);
    print('Status : ' + res.statusCode.toString());
    return (res.statusCode == 200) ? true : false;
  }

  Widget _title() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'Login',
        style: TextStyle(
          color: Colors.black,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _submitButton() {
    return InkWell(
      onTap: () async {
        setState(() {
          loginPressed = true;
        });
        var username = _emailController.text;
        var password = _passwordController.text;
        print("[username] : " + username);
        print("[password] : " + password);
        var logged = await attemptLogIn(username, password);
        print('Logged : ' + logged.toString());
        if (logged) {
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
          displayDialog(context, "An Error Occurred",
              "No account was found matching that username and password");
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Color(0xfff7892b),
        ),
        child: Text(
          'Login',
          style: TextStyle(
            //fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _entryField(String title, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(
            height: 10,
          ),
          TextField(
            obscureText: isPassword,
            controller: (isPassword) ? _passwordController : _emailController,
            decoration: InputDecoration(
              border: InputBorder.none,
              fillColor: Color(0xfff3f3f4),
              filled: true,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.only(
          left: 40,
          right: 40,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                    child: Column(
                  children: <Widget>[
                    _title(),
                    SizedBox(
                      height: 10,
                    ),
                    Icon(Icons.lock)
                  ],
                )),
                SizedBox(
                  height: 80,
                ),
                _entryField("Username"),
                _entryField("Password", isPassword: true),
                SizedBox(
                  height: 40,
                ),
                (loginPressed)
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      )
                    : _submitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
