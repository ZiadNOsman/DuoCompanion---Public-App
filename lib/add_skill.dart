import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'customskills.dart';

class AddSkill extends StatefulWidget {
  const AddSkill({Key? key}) : super(key: key);

  @override
  _AddSkillState createState() => _AddSkillState();
}

class _AddSkillState extends State<AddSkill> {
  bool translation_textfield_isempty = true;
  TextEditingController skillname_textfield = new TextEditingController();
  TextEditingController word_textfield = new TextEditingController();

  TextEditingController translation_textfield = new TextEditingController();
  var translationstoadd = [];
  var submiterror = "";

  @override
  void initState() {
    setState(() {
      translationstoadd = [];
      submiterror = "";
    });
    translation_textfield.addListener(() {
      if (translation_textfield.text.length != 0) {
        setState(() {
          translation_textfield_isempty = false;
        });
      } else {
        setState(() {
          translation_textfield_isempty = true;
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        title: Text(
          "Add a skill",
          style: TextStyle(fontFamily: "feather", color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        shadowColor: Colors.grey[50],
        actions: <Widget>[
          InkWell(
            onTap: () async {
              if (skillname_textfield.text == "") {
                setState(() {
                  submiterror = "Please enter a skill name";
                });
              } else if (word_textfield.text == "") {
                setState(() {
                  submiterror = "Please enter a word name";
                });
              } else if (translationstoadd.length == 0) {
                setState(() {
                  submiterror =
                      "Please enter at least one translation for your word. Make sure to press the + button after typing the translation";
                });
              } else {
                setState(() {
                  submiterror = "";
                });
                final prefs = await SharedPreferences.getInstance();
                // prefs.remove("customskills");
                var skills = [];
                // jsonDecode(prefs.getString("categories").toString());
                for (var skillname
                    in jsonDecode(prefs.getString("categories").toString())
                        .keys) {
                  skills.add(skillname);
                }
                if (skills.contains(skillname_textfield.text)) {
                  setState(() {
                    submiterror =
                        "The skill name you have chosen already exists";
                  });
                } else {
                  var customskills =
                      jsonDecode(prefs.getString("customskills").toString());
                  //in case there are no custom skills, initialize to an empty map
                  if (customskills == null || customskills == "null") {
                    customskills = {};
                    customskills[skillname_textfield.text] = {
                      word_textfield.text: translationstoadd
                    };
                    prefs.setString("customskills", jsonEncode(customskills));
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomSkills(),
                      ),
                    );
                  } else {
                    if (customskills.containsKey(skillname_textfield.text)) {
                      setState(() {
                        submiterror =
                            "There is already a custom skill with that name";
                      });
                    } else {
                      customskills[skillname_textfield.text] = {
                        word_textfield.text: translationstoadd
                      };

                      prefs.remove("customskills");
                      prefs.setString("customskills", jsonEncode(customskills));

                      //the following code was scraped because each time the sync button is pressed, all the custom skills will be gone.

                      // //add the skill to the prefs.categories
                      // //prefs.categories format is skillname: [list of words]

                      // var allcategories =
                      //     jsonDecode(prefs.getString("categories").toString());

                      // allcategories[skillname_textfield.text] = [
                      //   word_textfield.text
                      // ];
                      // prefs.remove("categories");
                      // prefs.setString("categories", jsonEncode(allcategories));
                      // //add the translation to the prefs.translations
                      // //prefs.translations format is word: [list of translations]

                      // var alltranslations = jsonDecode(
                      //     prefs.getString("translations").toString() ?? "");
                      // alltranslations[word_textfield.text] = translationstoadd;

                      // prefs.remove("translations");
                      // prefs.setString(
                      //     "translations", jsonEncode(alltranslations));
                      Navigator.pop(context);
                    }
                  }
                }
              }
            },
            child: Container(
                padding: EdgeInsets.only(
                  right: 15,
                ),
                child: Icon(
                  Icons.check,
                  size: 28,
                )),
          )
        ],
      ),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                submiterror == ""
                    ? Container()
                    : Container(
                        padding: EdgeInsets.only(top: 15, bottom: 15),
                        child: Text(
                          submiterror,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                TextField(
                  controller: skillname_textfield,
                  cursorColor: Colors.blue,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                      hintText: "Skill name",
                      hintStyle: TextStyle(
                          fontFamily: "feather",
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500]),
                      enabledBorder: const OutlineInputBorder(
                        // width: 0.0 produces a thin "hairline" border
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      border: const OutlineInputBorder()),
                ),
                SizedBox(
                  height: 15,
                ),
                TextField(
                  controller: word_textfield,
                  cursorColor: Colors.blue,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                      hintText: "enter a word",
                      hintStyle: TextStyle(
                          fontFamily: "feather",
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500]),
                      enabledBorder: const OutlineInputBorder(
                        // width: 0.0 produces a thin "hairline" border
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      border: const OutlineInputBorder()),
                ),
                SizedBox(
                  height: 15,
                ),
                TextField(
                  controller: translation_textfield,
                  cursorColor: Colors.blue,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                      suffixIcon: translation_textfield_isempty
                          ? null
                          : InkWell(
                              onTap: () {
                                setState(() {
                                  translationstoadd
                                      .add(translation_textfield.text);
                                });
                              },
                              child: Icon(Icons.add)),
                      hintText: "enter a translation",
                      hintStyle: TextStyle(
                          fontFamily: "feather",
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500]),
                      enabledBorder: const OutlineInputBorder(
                        // width: 0.0 produces a thin "hairline" border
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      border: const OutlineInputBorder()),
                ),
                translationstoadd.length != 0
                    ? Container(
                        child: Wrap(
                        children: [
                          for (var translation in translationstoadd)
                            Container(
                                padding: EdgeInsets.all(5),
                                child: IntrinsicWidth(
                                  child: TextFormField(
                                    initialValue: translation,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                        suffixIcon: InkWell(
                                      onTap: () {
                                        setState(() {
                                          translationstoadd.remove(translation);
                                        });
                                      },
                                      child: Icon(Icons.delete),
                                    )),
                                  ),
                                ))
                        ],
                      ))
                    : Container(),
                SizedBox(
                  height: 10,
                ),
                Center(
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Hint: you can add extra words after creating the skill",
                          style: TextStyle(fontSize: 25, color: Colors.grey),
                        ),
                      )),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
