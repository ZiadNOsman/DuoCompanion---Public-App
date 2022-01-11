import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:convert' show utf8;
import 'dart:convert';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:http/http.dart' as http;
import 'relatedsentences.dart';

class Mywords extends StatefulWidget {
  Mywords({Key? key}) : super(key: key);

  @override
  _MywordsState createState() => _MywordsState();
}

var allwords;
var staticallwords;
var pronounciations = {};
var finishedinitstate = false;

class _MywordsState extends State<Mywords> {
  @override
  var searching = false;
  var translatingfrom;
  var learninglang;
  var fromlanguage;
  var hinttext;
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
  TextEditingController textController = TextEditingController();

  retrievewords() async {
    final prefs = await SharedPreferences.getInstance();
    finishedinitstate = false;

    setState(() {
      var temp = prefs.getString("translations");
      var temp2 = prefs.getString("information").toString();
      learninglang = jsonDecode(temp2)["learning_language"];
      fromlanguage = jsonDecode(temp2)["from_language"];
      var temp3 = abbreviations[learninglang] ?? learninglang;
      hinttext = "Search from " + temp3;
      translatingfrom = learninglang;
      allwords = json.decode(temp ?? "");

      staticallwords = json.decode(temp ?? "");
      pronounciations = jsonDecode(prefs.getString("pronounciations") ?? "");

      //add custom words
      //format {skillname:{word1:[list of translations],word2:[]...},skillname2...}
      var customcategories =
          jsonDecode(prefs.getString("customskills").toString());
      if (customcategories == null) {
        customcategories = {};
      }
      for (var skillname in customcategories.keys) {
        for (var wordname in customcategories[skillname].keys) {
          allwords[wordname] = customcategories[skillname][wordname];
          staticallwords[wordname] = customcategories[skillname][wordname];
        }
      }

      finishedinitstate = true;
    });
  }

  @override
  void initState() {
    textController.addListener(_searchingfunc);
    super.initState();
    retrievewords();
  }

//for live search
  void _searchingfunc() async {
    var currtext = textController.text;
    allwords = staticallwords;
    //to know wether to display the x button next to the search bar
    if (currtext != "") {
      setState(() {
        searching = true;
      });
    } else {
      setState(() {
        searching = false;
      });
    }
    var searchingwords = {};
    //can only be resolved using nested for loops, but since the second for loop mostly breaks within the first time, its okay

    if (translatingfrom == fromlanguage) {
      for (var translations in allwords.keys) {
        for (var eachword in allwords[translations]) {
          if (eachword.toLowerCase().contains(currtext)) {
            searchingwords[translations] = allwords[translations];
            break;
          }
        }
      }
      setState(() {
        allwords = searchingwords;
      });
    } else {
      for (var translations in allwords.keys) {
        if (translations.contains(currtext)) {
          searchingwords[translations] = allwords[translations];
        }
      }
      setState(() {
        allwords = searchingwords;
      });
    }
    print(searchingwords);

    //print('Second text field: ${textController.text}');
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        shadowColor: Colors.grey[50],
        title: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(5)),
            child: TextField(
              style: TextStyle(fontSize: 17),
              controller: textController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hinttext,
                hintStyle: TextStyle(fontSize: 11, fontFamily: "feather"),
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: textController.clear,
                  icon: Icon(searching == true ? Icons.clear : null),
                ),
              ),
            )),
      ),
      body: finishedinitstate
          ? Center(
              child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // makenewcategory(
                //     "aaaaaaaaaaanwakjefniwejndjaewdweadiewndewnfdewadnweofnewkfnokfnajkfnoawnfoawenf",
                //     ["asfsadfaefasdfasdfasdfadsfasdfasdfasdfdasfads"]),

                for (var word in allwords.keys)
                  makenewcategory(
                      context,
                      word,
                      allwords[word] != null ? allwords[word] : "",
                      allwords[word] != null
                          ? pronounciations[word[0].toLowerCase() +
                                      word.substring(1)] !=
                                  null
                              ? pronounciations[
                                  word[0].toLowerCase() + word.substring(1)]
                              : ""
                          : ""),

                //for(var i=0;i<allwords.length;i++) makenewcategory(title, children)
              ],
            ))
          : CircularProgressIndicator(),
      bottomNavigationBar: ConvexButton.fab(
        icon: Icons.swap_horiz_outlined,
        iconSize: 40,
        thickness: 15,
        onTap: () {
          textController.clear();

          if (translatingfrom == learninglang) {
            setState(() {
              translatingfrom = fromlanguage;
              var temp = abbreviations[fromlanguage] ?? fromlanguage;
              hinttext = "Search from " + temp;
            });
          } else {
            setState(() {
              translatingfrom = learninglang;
              var temp = abbreviations[learninglang] ?? learninglang;
              hinttext = "Search from " + temp;
            });
          }
        },
      ),
    );
  }
}

//fuunction called to make new categories. it takes as arguments the title of the category and the children of the category
makenewcategory(BuildContext context, title, children, pronounciation) {
  return Container(
    decoration:
        BoxDecoration(border: Border.all(width: 0.05, color: Colors.grey)),
    child: ExpandableNotifier(
        child: Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        child: Column(
          children: <Widget>[
            SizedBox(
              child: Container(
                alignment: Alignment.topLeft,
                child: Text(
                  pronounciation,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
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
                      style: TextStyle(
                          fontSize: 22,
                          // color: Colors.grey[600],
                          fontWeight: FontWeight.bold),
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
                              padding: EdgeInsets.only(right: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    alignment: Alignment.topRight,
                                    child: InkWell(
                                      child: Text(
                                        "View related sentences",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      onTap: () async {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        var lexemid_list = json.decode(
                                            prefs.getString("lexemid_list") ??
                                                "");
                                        if (lexemid_list.containsKey(title)) {
                                          prefs.remove("relatedsentences_word");
                                          prefs.setString(
                                              "relatedsentences_word", title);
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      RelatedSentences()));
                                        } else {
                                          final snackBar = SnackBar(
                                              content: Text(
                                                  'Not supported for custom words'));

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  ElevatedButton(
                                    style: ButtonStyle(
                                        elevation:
                                            MaterialStateProperty.all<double>(
                                                0),
                                        shadowColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white10),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        fixedSize:
                                            MaterialStateProperty.all<Size?>(
                                                Size(55, 55))),
                                    child: Icon(
                                      Icons.volume_up_outlined,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      var lexemid_list = json.decode(
                                          prefs.getString("lexemid_list") ??
                                              "");
                                      if (lexemid_list.containsKey(title)) {
                                        var audioapiurl =
                                            "https://www.duolingo.com/api/1/dictionary_page?lexeme_id=";

                                        audioapiurl += lexemid_list[
                                            title[0].toLowerCase() +
                                                title.substring(1)];
                                        final audioapi = await http
                                            .get(Uri.parse(audioapiurl));
                                        if (audioapi.statusCode == 200) {
                                          print(audioapi.body);

                                          var audioapibody =
                                              jsonDecode(audioapi.body);
                                          if (audioapibody["has_tts"] == true) {
                                            print(audioapibody["tts"]);
                                            AudioPlayer player =
                                                new AudioPlayer();
                                            player.play(audioapibody["tts"]);
                                          } else {
                                            final snackBar = SnackBar(
                                                content: Text('No audio'));
                                            print("no audio");
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(snackBar);
                                          }
                                        } else {
                                          final snackBar = SnackBar(
                                              content:
                                                  Text('Something went wrong'));
                                          print("something went wrong");
// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }
                                      } else {
                                        final snackBar = SnackBar(
                                            content: Text(
                                                'Custom words do not have an audio'));

                                        // Find the ScaffoldMessenger in the widget tree
                                        // and use it to show a SnackBar.
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      }
                                    },
                                  )
                                ],
                              )),
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
                            )
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
