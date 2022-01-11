import 'package:flutter/material.dart';
import 'package:expandable_bottom_bar/expandable_bottom_bar.dart';
import 'package:http/http.dart';
import 'homepage.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:convert' show utf8;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rounded_loading_button/rounded_loading_button.dart';

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

var reverse_abbrv = {
  "Greek": "el",
  "Esperanto": "eo",
  "Swahili": "sw",
  "Italian": "it",
  "Welsh": "cy",
  "Scottish Gaelic": "gd",
  "Irish": "ga",
  "Czech": "cs",
  "Indonesian": "id",
  "Spanish": "es",
  "Chinese": "zs",
  "Russian": "ru",
  "Portuguese": "pt",
  "Latin": "la",
  "Dutch": "dn",
  "Norwegian (Bokmål)": "nb",
  "Turkish": "tr",
  "Vietnamese": "vi",
  "Romanian": "ro",
  "Polish": "pl",
  "Yiddish": "yi",
  "French": "fr",
  "German": "de",
  "High Valyrian": "hv",
  "Hawaiian": "hw",
  "Danish": "da",
  "Hindi": "hi",
  "Finnish": "fi",
  "Hungarian": "hu",
  "Japanese": "ja",
  "Hebrew": "he",
  "Korean": "ko",
  "Swedish": "sv",
  "Klingon": "kl",
  "Arabic": "ar",
  "Navajo": "nv",
  "Ukrainian": "uk",
  "English": "en"
};

var abrv_list = [
  "Greek",
  "Esperanto",
  "Swahili",
  "Italian",
  "Welsh",
  "Scottish Gaelic",
  "Irish",
  "Czech",
  "Indonesian",
  "Spanish",
  "Chinese",
  "Russian",
  "Portuguese",
  "Latin",
  "Dutch",
  "Norwegian (Bokmål)",
  "Turkish",
  "Vietnamese",
  "Romanian",
  "Polish",
  "Yiddish",
  "French",
  "German",
  "High Valyrian",
  "Hawaiian",
  "Danish",
  "Hindi",
  "Finnish",
  "Hungarian",
  "Japanese",
  "Hebrew",
  "Korean",
  "Swedish",
  "Klingon",
  "Arabic",
  "Navajo",
  "Ukrainian",
  "English"
];

var supported_directions = {
  "el": ["en"],
  "en": [
    "es",
    "fr",
    "de",
    "it",
    "ja",
    "zs",
    "ru",
    "ko",
    "pt",
    "ar",
    "dn",
    "sv",
    "nb",
    "tr",
    "pl",
    "ga",
    "el",
    "he",
    "da",
    "hi",
    "cs",
    "eo",
    "uk",
    "cy",
    "vi",
    "hu",
    "sw",
    "ro",
    "id",
    "hw",
    "nv",
    "kl",
    "hv",
    "la",
    "gd",
    "fi",
    "yi"
  ],
  "vi": ["en", "zs"],
  "it": ["en", "fr", "de", "es"],
  "ar": ["en", "fr", "de", "sv"],
  "cs": ["en"],
  "id": ["en"],
  "es": ["en", "fr", "it", "pt", "de", "ru", "ca", "eo", "gn", "sv"],
  "zs": ["en", "es", "ja", "ko", "it", "fr"],
  "ru": ["en", "de", "es", "fr"],
  "pt": ["en", "es", "fr", "de", "it", "eo"],
  "tr": ["en", "de", "ru"],
  "th": ["en"],
  "ro": ["en"],
  "pl": ["en"],
  "dn": ["en", "de", "fr"],
  "fr": ["en", "es", "it", "de", "pt", "eo"],
  "de": ["en", "es", "fr"],
  "hu": ["en", "de"],
  "hi": ["en"],
  "ja": ["en", "zs", "ko", "fr"],
  "ko": ["en"],
  "uk": ["en"]
};

var hassearched = false;
var validwordsearch = false;
var learninglang;
var fromlanguage;
var translatefrom = "";
var translateto = "";
var translationinformation;
var loadingsearch =
    false; //used to to disable textfield while the search api is retrieving the data

var can_translate_to = abrv_list;
TextEditingController wordsearchcontroller = TextEditingController();
final RoundedLoadingButtonController _syncwords =
    RoundedLoadingButtonController();
void main() => runApp(MaterialApp(home: Dictionary()));

class Dictionary extends StatefulWidget {
  @override
  State<Dictionary> createState() => _DictionaryState();
}

class _DictionaryState extends State<Dictionary> {
  @override
  getdata() async {
    setState(() {
      hassearched = false;

      validwordsearch = false;
      can_translate_to = abrv_list;
    });
    final prefs = await SharedPreferences.getInstance();
    var temp2 = prefs.getString("information").toString();
    learninglang = jsonDecode(temp2)["learning_language"];
    fromlanguage = jsonDecode(temp2)["from_language"];
    translateto = abbreviations[learninglang]!;
    translatefrom = abbreviations[fromlanguage]!;
  }

  void initState() {
    // TODO: implement initState
    wordsearchcontroller.addListener(() {
      _syncwords.reset();
    });
    super.initState();
    getdata();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultBottomBarController(
        child: Page(),
      ),
    );
  }
}

class Page extends StatefulWidget {
  Page({Key? key}) : super(key: key);

  @override
  _PageState createState() => _PageState();
}

class _PageState extends State<Page> {
  searchforword() async {
    setState(() {
      hassearched = true;
      loadingsearch = true;
      validwordsearch = false;
    });
    var tempapi = "https://d2.duolingo.com/api/1/dictionary/hints";
    var temp_translate_to;
    if (reverse_abbrv[translateto] != null) {
      temp_translate_to = reverse_abbrv[translateto];
    } else {
      temp_translate_to = translateto;
    }
    tempapi += "/" +
        reverse_abbrv[translatefrom]! +
        "/" +
        temp_translate_to +
        '?tokens=["';
    tempapi += wordsearchcontroller.text + '"]';
    final searchforwordapi = await http.get(Uri.parse(tempapi));
    if (searchforwordapi.statusCode == 200) {
      var bodymap = jsonDecode(searchforwordapi.body);
      if (bodymap[wordsearchcontroller.text].length == 0) {
        setState(() {
          validwordsearch = false;
        });
      } else {
        setState(() {
          validwordsearch = true;
          translationinformation = bodymap;
        });
      }
    } else {
      _syncwords.error();
    }
    setState(() {
      loadingsearch = false;
    });
    DefaultBottomBarController.of(context)!.swap();
    _syncwords.success();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,

      //Set to true for bottom appbar overlap body content
      extendBody: true,

      appBar: AppBar(
        title: Text(
          "Dictionary",
          style: TextStyle(
            fontFamily: "feather",
          ),
        ),
        backgroundColor: Colors.orange,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Homepage()));
          },
          icon: Icon(Icons.arrow_back_outlined),
        ),
      ),

      // Lets use docked FAB for handling state of sheet
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        // Set onVerticalDrag event to drag handlers of controller for swipe effect
        onVerticalDragUpdate: DefaultBottomBarController.of(context).onDrag,
        onVerticalDragEnd: DefaultBottomBarController.of(context).onDragEnd,
        child: FloatingActionButton.extended(
          label: Text("Pull up"),
          elevation: 2,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,

          //Set onPressed event to swap state of bottom bar
          onPressed: () {
            DefaultBottomBarController.of(context)!.swap();
            _syncwords.reset();
          },
        ),
      ),

      // Actual expandable bottom bar
      bottomNavigationBar: BottomExpandableAppBar(
        appBarHeight: 20,
        expandedHeight: MediaQuery.of(context).size.height * 0.8,
        horizontalMargin: MediaQuery.of(context).size.width * 0.02,
        shape: AutomaticNotchedShape(
            RoundedRectangleBorder(), StadiumBorder(side: BorderSide())),
        expandedBackColor: Colors.blueGrey,
        expandedBody: ListView(
            physics: const BouncingScrollPhysics(),
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.05),
            children: [
              Center(
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[100] ??
                                Colors.grey.withOpacity(0.6),
                            spreadRadius: 15,
                            blurRadius: 0,
                            offset: Offset(0, 0),
                          )
                        ]),
                    child: Column(
                      crossAxisAlignment: hassearched
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      mainAxisAlignment: hassearched
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        if (hassearched) ...[
                          if (validwordsearch) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(color: Colors.grey))),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  wordsearchcontroller.text,
                                  style: TextStyle(fontSize: 25),
                                ),
                              ),
                            ),
                            translationinformation[wordsearchcontroller.text] !=
                                    null
                                ? translationinformation[
                                                wordsearchcontroller.text]
                                            .length ==
                                        1
                                    ? Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.5,
                                        alignment: Alignment.center,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            translationinformation[
                                                wordsearchcontroller.text][0],
                                            style: TextStyle(
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                color: Colors.grey[600]),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: EdgeInsets.all(20),
                                        child: ListView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          children: [
                                            for (var wordtranslation
                                                in translationinformation[
                                                    wordsearchcontroller.text])
                                              FittedBox(
                                                alignment: Alignment.topLeft,
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  wordtranslation,
                                                  style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.06,
                                                      color: Colors.grey[700],
                                                      height: 1.5),
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                : Container()
                          ] else ...[
                            Container(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "Translation does not exit in Duolingo Dictionary.\n\nNote: words are case sensitive. ",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.red[700],
                                    fontFamily: "feather"),
                              ),
                            )
                          ]
                        ] else ...[
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "Please search for a word first",
                                  style: TextStyle(
                                      fontSize: 25, color: Colors.grey),
                                ),
                              ))
                        ]
                      ],
                    )),
              ),
            ]),
        bottomAppBarBody: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Text(
                  " ",
                  textAlign: TextAlign.center,
                ),
              ),
              Spacer(
                flex: 2,
              ),
              Expanded(
                child: Text(
                  "",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(physics: const BouncingScrollPhysics(), children: [
        Container(
          margin: EdgeInsets.all(20),
          child: Column(
            children: [
              DropdownSearch(
                searchDelay: Duration(),

                maxHeight: MediaQuery.of(context).size.height * 0.7,
                mode: Mode.BOTTOM_SHEET,
                label: "translate from",
                enabled: true,
                showSearchBox: true,

                items: abrv_list,
                // onFind: (String? searching) {
                //   var templist = [];
                //   for (var language in abrv_list) {
                //     if (language.contains(searching!)) {
                //       templist.add(language);
                //     }
                //   }
                //   return templist;
                // },

                onChanged: (String? data) {
                  setState(() {
                    translatefrom = data!;
                    //change the list of languages we can translate the word to based on the languagefrom we have chosen
                    if (supported_directions[reverse_abbrv[translatefrom]] !=
                        null) {
                      List<String> templist = [];
                      for (var language in supported_directions[
                          reverse_abbrv[translatefrom]]!) {
                        templist.add(abbreviations[language] ?? language);
                      }
                      setState(() {
                        can_translate_to = templist;
                      });
                    } else {
                      setState(() {
                        can_translate_to = abrv_list;
                      });
                    }
                  });
                },
                // selectedItem: abbreviations[fromlanguage],
              ),
              SizedBox(
                height: 30,
              ),
              DropdownSearch(
                searchDelay: Duration(),
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                mode: Mode.BOTTOM_SHEET,
                label: "translate to",
                enabled: true,
                showSearchBox: true,
                items: can_translate_to,
                onChanged: (String? data) {
                  setState(() {
                    translateto = data!;
                    //DefaultBottomBarController.of(context)!.swap();
                  });
                },
                // selectedItem: abbreviations[learninglang],
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                child: TextField(
                  enabled: !loadingsearch,
                  controller: wordsearchcontroller,
                  decoration: InputDecoration(
                    hintText: "word to translate",
                    enabledBorder: const OutlineInputBorder(
                      // width: 0.0 produces a thin "hairline" border
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 0.0),
                    ),
                    border: const OutlineInputBorder(),
                    labelStyle: new TextStyle(color: Colors.green),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              RoundedLoadingButton(
                color: Colors.white,
                successColor: Colors.green,
                errorColor: Colors.red,
                valueColor: Colors.black,
                borderRadius: 10,
                child: Text('Search',
                    style: TextStyle(color: Colors.black, fontSize: 20)),
                controller: _syncwords,
                onPressed: searchforword,
              )
            ],
          ),
        ),
      ]),
    );
  }
}
