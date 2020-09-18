import 'package:faceid_mobile/login/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:faceid_mobile/login/home_page.dart';
import 'dart:convert' show ascii, base64, json, utf8;


// Initializing the secure storage for state management
final storage = FlutterSecureStorage();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  Future<String> get logged async {
    var jwt = await storage.read(key: "jwt");
    if (jwt == null) return "";
    return jwt;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: logged,
        builder: (context, payload) {
          if (!payload.hasData) return CircularProgressIndicator();
          if (payload.data != "") {
            print("[Befor Splitted JWT]: " + payload.toString());
            var jwt = payload.data.toString().split(" ")[1].split(".");
            print("[Splitted JWT]: " + jwt[1]);
            print("[JWT Lenght]: " + jwt.length.toString());
            if (jwt.length != 3) {
              // return to the login Page
              return WelcomePage();
            } else {
              var decodedJwt = json.decode(
                  utf8.decode(base64.decode(base64.normalize(jwt[1]))));
              print("[Decoded JWT]: " + decodedJwt.toString());
              if (DateTime.fromMillisecondsSinceEpoch(decodedJwt["exp"] * 1000)
                  .isAfter(DateTime.now())) {
                //return to home page
                return HomePage(payload.data, decodedJwt);
              } else {
                // return to the login Page
                storage.delete(key: 'jwt');
                return WelcomePage();
              }
            }
          } else {
            // return to the login Page
            return WelcomePage();
          }
        },
      ),
    );
  }
}
