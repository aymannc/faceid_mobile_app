import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'home_page.dart';

const SERVER_IP = 'http://192.168.8.104:8083';
final storage = FlutterSecureStorage();

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  void displayDialog(context, title, text) => showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(title), content: Text(text)),
      );

  Future<String> attemptLogIn(String username, String password) async {
    var res = await http.post("$SERVER_IP/login",
        body: jsonEncode(<String, String>{'username': username, 'password': password}));
    print("[res] : " + res.headers['authorization']);
    if (res.statusCode == 200) return res.headers['authorization'];
    return null;
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
        var username = _emailController.text;
        var password = _passwordController.text;
        print("[username] : " + username);
        print("[password] : " + password);
        var jwt = await attemptLogIn(username, password);
        if (jwt != null) {
          storage.write(key: "jwt", value: jwt);
          // TODO : decode JwtTocken and store it to the secureStorage
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage.fromBase64(jwt)));
        } else {
          displayDialog(context, "An Error Occurred", "No account was found matching that username and password");
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
                _entryField("Email"),
                _entryField("Password", isPassword: true),
                SizedBox(
                  height: 40,
                ),
                _submitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
