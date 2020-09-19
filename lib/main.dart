import 'package:faceid_mobile/login/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:faceid_mobile/login/home_page.dart';

// Initializing the secure storage for state management
final storage = FlutterSecureStorage();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  Future<String> get logged async {
    var username = await storage.read(key: "username");
    if (username == null) return "";
    return username;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: FutureBuilder(
        future: logged,
        builder: (context, payload) {
          if (!payload.hasData) return CircularProgressIndicator();
          return (payload.data != '') ? HomePage(payload.data) : WelcomePage();
        },
      ),
    );
  }
}
