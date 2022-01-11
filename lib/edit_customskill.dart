import 'package:flutter/material.dart';
import 'package:flutter_application_1/customskills.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:expandable/expandable.dart';
import 'addskillsgroup.dart';
import 'add_customwords.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class EditCustomSkill extends StatefulWidget {
  const EditCustomSkill({Key? key}) : super(key: key);

  @override
  _EditCustomSkillState createState() => _EditCustomSkillState();
}

class _EditCustomSkillState extends State<EditCustomSkill> {
  var finishedinitstate = false;
  var skill;
  getdata() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      skill = jsonDecode(prefs.getString("editskill").toString());
    });
    print(skill);
    setState(() {
      finishedinitstate = true;
    });
  }

  @override
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
            "Edit Skill",
            style: TextStyle(fontFamily: "feather", color: Colors.white),
          ),
          actions: <Widget>[
            InkWell(
              onTap: () async {
                AwesomeDialog(
                    btnCancelOnPress: () {},
                    btnOkText: "Yes",
                    // dismissOnTouchOutside: false,
                    // autoHide: Duration(seconds: 2),
                    context: context,
                    // dialogType: DialogType.SUCCES,
                    animType: AnimType.BOTTOMSLIDE,
                    title:
                        "Are you sure you want to delete the skill ${skill["skillname"]}?",
                    btnOkOnPress: () async {
                      final prefs = await SharedPreferences.getInstance();
                      var customskills = jsonDecode(
                          prefs.getString("customskills").toString());

                      customskills.removeWhere(
                          (key, value) => key == skill["skillname"]);
                      prefs.remove("customskills");
                      prefs.setString("customskills", jsonEncode(customskills));
                      Navigator.pop(context);
                    })
                  ..show();
              },
              child: Container(
                  padding: EdgeInsets.only(right: 15),
                  child: Icon(
                    Icons.delete,
                    size: 28,
                  )),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCustomWords()),
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
            ),
          ],
          backgroundColor: Colors.orange,
          shadowColor: Colors.grey[50],
        ),
        body: finishedinitstate
            ? ListView(
                children: [
                  for (var word in skill["words"].keys)
                    makenewcategory(context, word, skill["words"][word]),
                  SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Hint: press + to add new words",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )),
                  )
                ],
              )
            : Center(
                child: CircularProgressIndicator(),
              ));
  }

  makenewcategory(BuildContext context, title, children) {
    return Container(
      decoration:
          BoxDecoration(border: Border.all(width: 0.2, color: Colors.grey)),
      child: ExpandableNotifier(
          child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          child: Column(
            children: <Widget>[
              //you can put a child here, such as an image. it will go before the card title
              ScrollOnExpand(
                scrollOnExpand: true,
                scrollOnCollapse: false,
                child: ExpandablePanel(
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                    tapBodyToCollapse:
                        false, //change to specify whether to collapse the content or click of the body
                  ),
                  header: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 18, fontFamily: "feather"
                            // color: Colors.grey[600],
                            ),
                        // style: Theme.of(context).textTheme.bodyText1,
                      )),
                  collapsed: Text(
                      ""), //specify this field to have some children visible even while collapsed
                  // Text(
                  //   loremIpsum,
                  //   softWrap: true,
                  //   maxLines: 2,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  expanded: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Column(children: [
                            Container(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () {
                                  AwesomeDialog(
                                    btnCancelOnPress: () {},
                                    btnOkText: "Yes",
                                    // dismissOnTouchOutside: false,
                                    // autoHide: Duration(seconds: 2),
                                    context: context,
                                    // dialogType: DialogType.SUCCES,
                                    animType: AnimType.BOTTOMSLIDE,
                                    title:
                                        "Are you sure you want to delete the word ${title}?",

                                    btnOkOnPress: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      var customskills = jsonDecode(prefs
                                          .getString("customskills")
                                          .toString());

                                      var wordcount = 0;
                                      for (var word in skill["words"].keys) {
                                        wordcount += 1;
                                      }

                                      if (wordcount != 1) {
                                        customskills[skill["skillname"]]
                                            .removeWhere(
                                                (key, value) => key == title);

                                        setState(() {
                                          skill["words"].removeWhere(
                                              (key, value) => key == title);
                                        });

                                        prefs.remove("editskill");
                                        prefs.setString(
                                            "editskill", jsonEncode(skill));

                                        prefs.remove("customskills");
                                        prefs.setString("customskills",
                                            jsonEncode(customskills));

                                        final snackBar = SnackBar(
                                          content: Text("Removed ${title}"),
                                          behavior: SnackBarBehavior.floating,
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      } else {
                                        final snackBar = SnackBar(
                                          content: Text(
                                              "Cannot delete last word from skill"),
                                          behavior: SnackBarBehavior.floating,
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      }
                                    },
                                  )..show();
                                },
                                child: Icon(Icons.delete),
                              ),
                            ),
                            for (var i = 0; i < children.length; i++)
                              Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(
                                    top: 10, bottom: 10, left: 10),
                                child: Text(
                                  "• " + children[i],
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 16),
                                ),
                              ),
                            Container(
                                alignment: Alignment.topRight,
                                padding: EdgeInsets.only(right: 5, top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: 15,
                                    ),
                                  ],
                                )),
                          ])),
                    ],
                  ),
                  builder: (_, collapsed, expanded) {
                    return Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                      child: Expandable(
                        collapsed: collapsed,
                        expanded: expanded,
                        theme: const ExpandableThemeData(
                          crossFadePoint: 0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
