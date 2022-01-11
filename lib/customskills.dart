import 'package:flutter/material.dart';
import 'package:flutter_application_1/dictionary.dart';
import 'add_skill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'edit_customskill.dart';

class CustomSkills extends StatefulWidget {
  const CustomSkills({Key? key}) : super(key: key);

  @override
  _CustomSkillsState createState() => _CustomSkillsState();
}

class _CustomSkillsState extends State<CustomSkills> {
  @override
  var customskills;
  var finishedinitstate = false;
  getdata() async {
    final prefs = await SharedPreferences.getInstance();
    customskills = jsonDecode(prefs.getString("customskills").toString());
    if (customskills == null) {
      customskills = {};
    }
    setState(() {
      finishedinitstate = true;
    });
  }

  void initState() {
    setState(() {
      finishedinitstate = false;
    });
    // TODO: implement initState
    super.initState();
    getdata();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        title: Text(
          "Custom Skills",
          style: TextStyle(fontFamily: "feather", color: Colors.white),
        ),
        actions: <Widget>[
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddSkill()),
              ).then((value) => setState(() {
                    getdata();
                  }));
            },
            child: Container(
                padding: EdgeInsets.only(right: 15),
                child: Icon(
                  Icons.add,
                  size: 28,
                )),
          )
        ],
        backgroundColor: Colors.orange,
        shadowColor: Colors.grey[50],
      ),
      body: finishedinitstate
          ? Center(
              child: customskills.length == 0
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Create custom skills to see them here",
                          style: TextStyle(fontSize: 25, color: Colors.grey),
                        ),
                      ))
                  : ListView(
                      children: [
                        for (var skillname in customskills.keys)
                          Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                bottom:
                                    BorderSide(color: Colors.grey, width: 0.5),
                              )),
                              child: TextFormField(
                                style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 18,
                                    fontFamily: "feather"),
                                readOnly: true,
                                initialValue: skillname,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.only(
                                        left: 10, top: 18, bottom: 18),
                                    suffixIcon: InkWell(
                                        onTap: () async {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          prefs.remove("editskill");
                                          prefs.setString(
                                              "editskill",
                                              jsonEncode({
                                                "skillname":
                                                    skillname.toString(),
                                                "words": customskills[skillname]
                                              }));
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    EditCustomSkill()),
                                          ).then((value) => setState(() {
                                                getdata();
                                              }));
                                        },
                                        child: Icon(Icons.edit))),
                              ))
                      ],
                    ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
