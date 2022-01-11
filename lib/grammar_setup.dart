import 'package:flutter/material.dart';
// import 'package:localstorage/localstorage.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'grammar.dart';
import 'package:group_button/group_button.dart';

// final storage = LocalStorage("duolearnedword.json");
// var testvar = storage.getItem("information");
// Map valueMap = json.decode(testvar);
var information;
var categories;
var nbofwords = 10.0;
var incompleteform = false;
var invertflashcards = false;

class GrammarSetup extends StatefulWidget {
  GrammarSetup({Key? key}) : super(key: key);

  @override
  _GrammarSetupState createState() => _GrammarSetupState();
}

class _GrammarSetupState extends State<GrammarSetup> {
  @override
  var tempinformation = '';
  var tempcategories = '';

  var onlycategories = [];
  var _myActivities = [];
  var abbreviations = {
    "el": "Greek",
    "eo": "Esperanto",
    "sw": "Swahili",
    "it": "Italian",
    "cy": "Welsh",
    "gd": "Scottish Gaelic",
    "ga": "Irish",
    "cs": "Czech",
    "id": "Indonesian",
    "es": "Spanish",
    "zs": "Chinese",
    "ru": "Russian",
    "pt": "Portuguese",
    "la": "Latin",
    "dn": "Dutch",
    "nb": "Norwegian (Bokmål)",
    "tr": "Turkish",
    "vi": "Vietnamese",
    "ro": "Romanian",
    "pl": "Polish",
    "yi": "Yiddish",
    "fr": "French",
    "de": "German",
    "hv": "High Valyrian",
    "hw": "Hawaiian",
    "da": "Danish",
    "hi": "Hindi",
    "fi": "Finnish",
    "hu": "Hungarian",
    "ja": "Japanese",
    "he": "Hebrew",
    "ko": "Korean",
    "sv": "Swedish",
    "kl": "Klingon",
    "ar": "Arabic",
    "nv": "Navajo",
    "uk": "Ukrainian",
    "en": "English"
  };
  var finishedinitstate = false;
  var gamemode = "categories";

  getdata() async {
    setState(() {
      nbofwords = 10;
      finishedinitstate = false;
      incompleteform = false;
      gamemode = "categories";
    });
    final prefs = await SharedPreferences.getInstance();
    tempinformation = prefs.getString("information").toString();

    tempcategories = prefs.getString("categories").toString();
    information = json.decode(tempinformation);
    categories = json.decode(tempcategories);
    for (var cats in categories.keys) {
      onlycategories.add(cats);
    }
    //add the custom categories
    //format {skillname:{word1:[list of translations],word2:[]...},skillname2...}
    var customcategories =
        jsonDecode(prefs.getString("customskills").toString());
    if (customcategories == null) {
      customcategories = {};
    }
    for (var customcat in customcategories.keys) {
      onlycategories.add(customcat);

      var templist = [];
      for (var customword in customcategories[customcat].keys) {
        templist.add(customword);
      }
      categories[customcat] = templist;
    }
    onlycategories.sort((a, b) => a.toString().compareTo(b.toString()));

    //print(prefs.getString("translations"));
    setState(() {
      finishedinitstate = true;
    });
  }

  void initState() {
    // TODO: implement initState
    super.initState();

    getdata();
  }

  _saveForm() async {
    if (gamemode == "categories") {
      if (nbofwords > 0 && _myActivities.length > 0) {
        print(_myActivities);
        final prefs = await SharedPreferences.getInstance();

        var chosencategories = {};
        for (var cat in _myActivities) {
          chosencategories[cat] = categories[cat];
        }
        print(chosencategories);
        prefs.remove("flashcards_categories");
        prefs.remove("flashcards_nbofwords");
        prefs.remove("gamemode_categories");
        prefs.remove("invertflashcards");
        prefs.setString("invertflashcards", "true");
        prefs.setString('flashcards_categories', jsonEncode(chosencategories));
        prefs.setString("flashcards_nbofwords", nbofwords.toInt().toString());

        prefs.setString("gamemode_categories", "true");
        //save categories and number of words to local storage
        //redirect to flashcards page
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Grammar()));
      } else {
        setState(() {
          incompleteform = true;
        });
      }
    } else if (gamemode == "leastpracticedwords") {
      if (nbofwords > 0) {
        final prefs = await SharedPreferences.getInstance();
        prefs.remove("flashcards_nbofwords");
        prefs.remove("gamemode_categories");
        prefs.remove("invertflashcards");
        prefs.setString("invertflashcards", 'true');
        prefs.setString("flashcards_nbofwords", nbofwords.toInt().toString());

        prefs.setString("gamemode_categories", "leastpracticedwords");

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Grammar()));
      } else {
        setState(() {
          incompleteform = true;
        });
      }
    }
  }

  String errormsg() {
    if (gamemode == "categories") {
      if (nbofwords <= 0) {
        return 'Please select the number of words';
      } else if (_myActivities.length == 0) {
        return 'Please choose at least one skill';
      } else {
        return '';
      }
    } else if (gamemode == "leastpracticedwords") {
      if (nbofwords <= 0) {
        return 'Please select the number of words';
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        shadowColor: Colors.grey[50],
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Setup",
          style: TextStyle(color: Colors.white, fontFamily: 'feather'),
        ),
      ),
      body: Container(
          child: ScrollConfiguration(
        behavior: ScrollBehavior(),
        child: GlowingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          color: Colors.orange,
          child: ListView(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  AnimatedFlipCounter(
                    suffix: " Words",
                    textStyle: TextStyle(
                      fontSize: 30,
                      fontFamily: 'feather',
                    ),
                    duration: Duration(milliseconds: 500),
                    value: nbofwords, // pass in a value like 2014
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  ButtonBar(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      counterbutton(() {
                        if (nbofwords > 0) {
                          setState(() {
                            nbofwords -= 10;
                            if (nbofwords < 0) {
                              nbofwords = 0;
                            }
                          });
                        }
                      }, "-10"),
                      counterbutton(() {
                        if (nbofwords > 0) {
                          setState(() {
                            nbofwords -= 1;
                            if (nbofwords < 0) {
                              nbofwords = 0;
                            }
                          });
                        }
                      }, "-1"),
                      counterbutton(() {
                        setState(() {
                          nbofwords += 1;
                        });
                      }, "+1"),
                      counterbutton(() {
                        setState(() {
                          nbofwords += 10;
                        });
                      }, "+10")
                    ],
                  ),
                  finishedinitstate
                      ? GroupButton(
                          spacing: 5,
                          isRadio: true,
                          direction: Axis.horizontal,
                          onSelected: (index, isSelected) {
                            if (index == 0) {
                              setState(() {
                                gamemode = "categories";
                              });
                            } else if (index == 1) {
                              setState(() {
                                gamemode = "leastpracticedwords";
                              });
                            }
                          },
                          buttons: ["Skills", "Least mastered"],
                          selectedButton: 0,

                          /// [List<int>] after 2.2.1 version
                          selectedTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          unselectedTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          selectedColor: Colors.white,
                          unselectedColor: Colors.grey[300],
                          selectedBorderColor: Colors.red,
                          unselectedBorderColor: Colors.grey[500],
                          borderRadius: BorderRadius.circular(5.0),
                          selectedShadow: <BoxShadow>[
                            BoxShadow(color: Colors.transparent)
                          ],
                          unselectedShadow: <BoxShadow>[
                            BoxShadow(color: Colors.transparent)
                          ],
                        )
                      : Text(""),
                  finishedinitstate
                      ? gamemode == "categories"
                          ? Container(
                              padding: EdgeInsets.all(20),
                              child: DropdownSearch.multiSelection(
                                searchDelay: Duration(),
                                searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                        labelText: "Search for skills")),
                                label: "Skills",
                                hint:
                                    "Choose the skills you would like to practice",
                                showClearButton: true,
                                mode: Mode.DIALOG,
                                enabled: true,
                                showSearchBox: true,
                                items: onlycategories,
                                onChange: (List? data) {
                                  print(data);
                                  setState(() {
                                    _myActivities = data ?? [];
                                  });
                                },
                              ),
                            )
                          : Container()
                      : CircularProgressIndicator(),
                  incompleteform
                      ? Container(
                          child: Text(
                            errormsg(),
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        )
                      : Container(),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                        left: 50, right: 50, top: 20, bottom: 10),
                    child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.green),
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              EdgeInsets.all(15)),
                        ),
                        onPressed: () async {
                          setState(() {
                            _saveForm(); //to validate that at least one category was chosen.
                          });
                        },
                        child: Text("Start Game")),
                  )
                ],
              )
            ],
          ),
        ),
      )),
    );
  }

  counterbutton(VoidCallback func, String count) {
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(5), boxShadow: [
        BoxShadow(
          color: Colors.grey[100] ?? Colors.grey.withOpacity(0.6),
          spreadRadius: -5,
          blurRadius: 5,
          offset: Offset(0, 7),
        )
      ]),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5))),
          onPressed: func,
          child: Text(
            count,
            style: TextStyle(color: Colors.black),
          )),
    );
  }
}
