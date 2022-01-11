import 'package:flutter/material.dart';
import 'homepage.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

//this page was made to avoid a visible redirect from login page to homepage each time we open the app.

class Isloggedin extends StatefulWidget {
  Isloggedin({Key? key}) : super(key: key);

  @override
  _IsloggedinState createState() => _IsloggedinState();
}

class _IsloggedinState extends State<Isloggedin> {
  @override
  checkloginstatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("identifier") != null &&
        prefs.getString("password") != null) {
      print("ur logged in");
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Homepage()));
    } else {
      print("ur not logged in");
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyHomePage(
                    title: "Login",
                  )));
    }
  }

  void initState() {
    // TODO: implement initState
    super.initState();
    checkloginstatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
