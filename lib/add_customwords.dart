import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class AddCustomWords extends StatefulWidget {
  const AddCustomWords({Key? key}) : super(key: key);

  @override
  _AddCustomWordsState createState() => _AddCustomWordsState();
}

class _AddCustomWordsState extends State<AddCustomWords> {
  bool translation_textfield_isempty = true;
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
          "Add Words",
          style: TextStyle(fontFamily: "feather", color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        shadowColor: Colors.grey[50],
        actions: <Widget>[
          InkWell(
            onTap: () async {
              if (word_textfield.text == "") {
                setState(() {
                  submiterror = "Please enter a word name";
                });
              } else if (translationstoadd.length == 0) {
                setState(() {
                  submiterror =
                      "Please enter at least one translation for your word. Make sure to press the add button after typing the translation";
                });
              } else {
                setState(() {
                  submiterror = "";
                });
                final prefs = await SharedPreferences.getInstance();
                // prefs.remove("customskills");
                var wordsinskill = [];
                var skilltoedit =
                    jsonDecode(prefs.getString("editskill").toString());
                var customskills =
                    jsonDecode(prefs.getString("customskills").toString());

                var turntomap = new Map<String, dynamic>.from(
                    customskills[skilltoedit["skillname"]]);
                print(customskills);
                for (var word in turntomap.keys) {
                  wordsinskill.add(word);
                }
                if (wordsinskill.contains(word_textfield.text)) {
                  setState(() {
                    submiterror = "This word already exists in this skill";
                  });
                } else {
                  //add an entry inside the skill map under the form word:[array of translations]
                  //modify the "customskills[skilltoedit["skillname"]]". in other words add the new word to the skill which is inside the "customskills"
                  turntomap[word_textfield.text] = translationstoadd;
                  customskills[skilltoedit["skillname"]] = turntomap;
                  print(customskills);

                  prefs.remove("customskills");
                  prefs.setString("customskills", jsonEncode(customskills));

                  //modify the prefs.editskill entry
                  // this is done to make sure the previous page displays the new word
                  //prefs.editskill format {skillname: skill name, words:{word:[translation],word2...}}
                  var editskill =
                      jsonDecode(prefs.getString("editskill").toString());

                  editskill["words"][word_textfield.text] = translationstoadd;
                  prefs.remove("editskill");
                  prefs.setString("editskill", jsonEncode(editskill));

                  setState(() {
                    word_textfield.text = "";
                    translationstoadd = [];
                  });
                  final snackBar = SnackBar(
                    content: Text("Added the word ${word_textfield.text}"),
                    behavior: SnackBarBehavior.floating,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }

                // else {
                //   var customskills =
                //       jsonDecode(prefs.getString("customskills").toString());

                //   if (customskills.containsKey(skillname_textfield.text)) {
                //     setState(() {
                //       submiterror =
                //           "There is already a custom skill with that name";
                //     });
                //   } else {
                //     customskills[skillname_textfield.text] = {
                //       word_textfield.text: translationstoadd
                //     };

                //     prefs.remove("customskills");
                //     prefs.setString("customskills", jsonEncode(customskills));
                //     Navigator.pushReplacement(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => CustomSkills(),
                //       ),
                //     );
                //   }
                // }
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
                    : Container()
              ],
            ),
          )
        ],
      ),
    );
  }
}
