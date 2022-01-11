import 'dart:convert';
import 'dart:io';

import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/setup.dart';
import 'package:tcard/tcard.dart';
import 'package:flip_card/flip_card.dart';
import 'package:percent_indicator/percent_indicator.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'relatedsentences.dart';

class Flashcards extends StatefulWidget {
  Flashcards({Key? key}) : super(key: key);

  @override
  _FlashcardsState createState() => _FlashcardsState();
}

class _FlashcardsState extends State<Flashcards> {
  _makeflipcard(var frontword, var backtranslation, var cardkey) {
    // print("nb of card keys is: " + flipcards_controllers_list.length.toString());
    if (invertflashcards == false) {
      return FlipCard(
          key: cardkey,
          direction: FlipDirection.HORIZONTAL, // default
          front: Container(
            padding: EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      children: [
                        pronounciations.containsKey(frontword[0].toLowerCase() +
                                frontword.substring(1))
                            ? Text(
                                "(" +
                                    pronounciations[frontword[0].toLowerCase() +
                                        frontword.substring(1)] +
                                    ")",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.grey[600]),
                              )
                            : Container(),
                        Text(
                          frontword,
                          style: TextStyle(fontSize: 40),
                        ),
                      ],
                    )),
                SizedBox(
                  height: 10,
                ),
                Center(
                  child: Text(
                    "Tap to show answer",
                    style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 14),
                  ),
                )
              ],
            ),
          ),
          back: backtranslation != null
              ? backtranslation.length == 1
                  ? Container(
                      padding: EdgeInsets.all(20),
                      height: 20,
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          backtranslation[0],
                          style: TextStyle(
                            fontSize: 40,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: [
                            for (var wordtranslation in backtranslation)
                              FittedBox(
                                alignment: Alignment.center,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  wordtranslation,
                                  style: TextStyle(
                                      fontSize: 28,
                                      color: Colors.black,
                                      height: 1.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
              : Text(""));
    } else {
      return FlipCard(
          key: cardkey,
          direction: FlipDirection.HORIZONTAL, // default
          back: Container(
            padding: EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      children: [
                        pronounciations.containsKey(frontword[0].toLowerCase() +
                                frontword.substring(1))
                            ? Text(
                                "(" +
                                        pronounciations[
                                            frontword[0].toLowerCase() +
                                                frontword.substring(1)] +
                                        ")" ??
                                    "",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.grey[600]),
                              )
                            : Container(),
                        Text(
                          frontword,
                          style: TextStyle(fontSize: 40),
                        ),
                      ],
                    )),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
          front: backtranslation != null
              ? backtranslation.length == 1
                  ? Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(20),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        children: [
                          FittedBox(
                              alignment: Alignment.center,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                backtranslation[0],
                                style: TextStyle(
                                  fontSize: 40,
                                ),
                              )),
                          FittedBox(
                            alignment: Alignment.center,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Tap to show answer",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                        ],
                      ))
                  : Center(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: [
                            FittedBox(
                              alignment: Alignment.center,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Tap to show answer",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14),
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            for (var wordtranslation in backtranslation)
                              FittedBox(
                                alignment: Alignment.center,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  wordtranslation,
                                  style: TextStyle(
                                      fontSize: 28,
                                      color: Colors.black,
                                      height: 1.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
              : Text(""));
    }
  }

  var translations = {};
  var flashcard_words_list = [];
  var flipcards_controllers_list;
  var cards;
  var hasfinishedloading = false;
  var invertflashcards = false;
  var pronounciations = {};

  var wordsfinished = 0;
  var percentage = 0.0;
  @override
  void initState() {
    super.initState();
    cards = [];
    translations = {};
    flashcard_words_list = [];
    flipcards_controllers_list = [];
    setState(() {
      hasfinishedloading = false;
    });
    _initializegame();
  }

  _initializegame() async {
    final prefs = await SharedPreferences.getInstance();
    invertflashcards =
        json.decode(prefs.getString("invertflashcards") ?? "false");
    pronounciations = jsonDecode(prefs.getString("pronounciations") ?? "");

    var gamemode_categories = prefs.getString("gamemode_categories");
    if (gamemode_categories == "true") {
      var categories_chosen =
          jsonDecode(prefs.getString("flashcards_categories") ?? "");
      for (var chosencat in categories_chosen.keys) {
        flashcard_words_list += categories_chosen[chosencat];
      }
    } else if (gamemode_categories == 'leastpracticedwords') {
      var leastpracticedwords_map =
          jsonDecode(prefs.getString('words_strength_map') ?? "");
      print(leastpracticedwords_map);
      for (var word in leastpracticedwords_map.keys) {
        print(word);
        flashcard_words_list.add(word);
      }
    }
    var nbofwords = prefs.getString("flashcards_nbofwords");

    translations = json.decode(prefs.getString('translations') ?? "");

    //add custom words translations
    //format {skillname:{word1:[list of translations],word2:[]...},skillname2...}
    var customcategories =
        jsonDecode(prefs.getString("customskills").toString());
    if (customcategories == null) {
      customcategories = {};
    }
    for (var customskill in customcategories.keys) {
      for (var customword in customcategories[customskill].keys) {
        translations[customword] = customcategories[customskill][customword];
      }
    }

    //make sure there is a translation. if there is isnt, make sure there is one if the first character is capitalized, else discard the word
    var temp_words_todelete_list = [];
    var temp_words_toadd_list = [];
    for (var word in flashcard_words_list) {
      if (translations[word] == null) {
        //set it to be removed from list
        temp_words_todelete_list.add(word);
        //if no translation
        var capitalizedword = word[0].toUpperCase() +
            word.substring(
                1); //check if translation exists with first character capitalized
        if (translations[capitalizedword] != null) {
          //set it to be removed and add its capitalized counterpart
          temp_words_toadd_list.add(capitalizedword);
        }
      }
    }
    //words cant be removed from list while its being iterated, so we make a second for loop to remove the elements that had no translations.

    for (var wordtodelete in temp_words_todelete_list) {
      flashcard_words_list.removeWhere((element) => element == wordtodelete);
    }

    //likewise, we need a forloop to add the new words.

    for (var wordtoadd in temp_words_toadd_list) {
      flashcard_words_list.add(wordtoadd);
    }

    //remove duplicate words
    flashcard_words_list = flashcard_words_list.toSet().toList();
    //if the game mode is leastpracticedwords, take a subset, then shuffle
    if (gamemode_categories == 'leastpracticedwords') {
      //if the number of words chosen is smaller than the total number of words chosen
      if (nbofwords != null) {
        if (int.parse(nbofwords) < flashcard_words_list.length) {
          flashcard_words_list =
              flashcard_words_list.sublist(0, int.parse(nbofwords));
        }
      }
      //shuffle list
      flashcard_words_list.shuffle();
    } else if (gamemode_categories == 'true') {
      //shuffle list
      flashcard_words_list.shuffle();
      //if the number of words chosen is smaller than the total number of words chosen
      if (nbofwords != null) {
        if (int.parse(nbofwords) < flashcard_words_list.length) {
          flashcard_words_list =
              flashcard_words_list.sublist(0, int.parse(nbofwords));
        }
      }
    }

    flipcards_controllers_list = new List.generate(
        flashcard_words_list.length, (index) => GlobalKey<FlipCardState>());

    cards = List.generate(
        flashcard_words_list.length,
        (index) => Container(
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey[200]!,
                        spreadRadius: 3,
                        blurRadius: 3)
                  ],
                  border: Border.all(
                      color: Colors.grey[200]! ?? Colors.grey, width: 2),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: _makeflipcard(
                  flashcard_words_list[index],
                  translations[flashcard_words_list[index]],
                  flipcards_controllers_list[index]),
            ));

    setState(() {
      hasfinishedloading = true;
    });
  }
  //we have to make a controller for each flipcard, otherwise if you flip a card, all other cards get flipped as well

  TCardController flashcardscontroller = new TCardController();
  final RoundedLoadingButtonController _audiobuttoncontroller =
      RoundedLoadingButtonController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        bottomOpacity: 0.0,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.only(left: 20),
                child: CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 3,
                  percent: percentage,
                  animation: true,
                  circularStrokeCap: CircularStrokeCap.round,
                  animateFromLastPercent: true,
                  center: new Text("${(percentage * 100).round()} %",
                      style: TextStyle(
                          color: Colors.grey[700], fontFamily: "feather")),
                  backgroundColor: Colors.white,
                  progressColor: Colors.lightGreenAccent[700],
                ),
              ),
              Container(
                padding: EdgeInsets.only(right: 20),
                child: RoundedLoadingButton(
                  width: 65,
                  height: 65,
                  color: Colors.white,
                  valueColor: Colors.blue,
                  borderRadius: 5,
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    var lexemid_list =
                        json.decode(prefs.getString("lexemid_list") ?? "");
                    if (lexemid_list
                        .containsKey(flashcard_words_list[wordsfinished])) {
                      var audioapiurl =
                          "https://www.duolingo.com/api/1/dictionary_page?lexeme_id=";

                      audioapiurl +=
                          lexemid_list[flashcard_words_list[wordsfinished]];
                      final audioapi = await http.get(Uri.parse(audioapiurl));
                      if (audioapi.statusCode == 200) {
                        print(audioapi.body);

                        var audioapibody = jsonDecode(audioapi.body);
                        if (audioapibody["has_tts"] == true) {
                          print(audioapibody["tts"]);
                          AudioPlayer player = new AudioPlayer();
                          player.play(audioapibody["tts"]);
                        } else {
                          final snackBar = SnackBar(content: Text('No audio'));

                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      } else {
                        final snackBar =
                            SnackBar(content: Text('Something went wrong'));

                        // Find the ScaffoldMessenger in the widget tree
                        // and use it to show a SnackBar.
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                      _audiobuttoncontroller.reset();
                    } else {
                      final snackBar = SnackBar(
                          content: Text('Custom words do not have an audio'));

                      // Find the ScaffoldMessenger in the widget tree
                      // and use it to show a SnackBar.
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      _audiobuttoncontroller.reset();
                    }
                  },
                  child: Icon(
                    Icons.volume_up_outlined,
                    color: Colors.blue,
                  ),
                  controller: _audiobuttoncontroller,
                ),
              ),
            ],
          ),
          Center(
              child: hasfinishedloading
                  ? TCard(
                      delaySlideFor: 100,
                      slideSpeed: 40,
                      controller: flashcardscontroller,
                      onForward: (index, info) {
                        _audiobuttoncontroller.reset();
                        //here, make sure if its swiped left or right.
                        // _initializegame();
                        print(index);
                        // cardKey.currentState.toggleCard();
                        // also make sure the card has not been visited yet. ex: pressed back then forward

                        wordsfinished += 1;
                        setState(() {
                          percentage =
                              wordsfinished / flashcard_words_list.length;
                          percentage = percentage.toDouble();
                        });
                      },
                      onBack: (index, info) {
                        _audiobuttoncontroller.reset();
                        print(index);
                        cards[index].hashCode;
                        wordsfinished -= 1;
                        setState(() {
                          percentage =
                              wordsfinished / flashcard_words_list.length;
                          percentage = percentage.toDouble();
                        });

                        // //FLIPCARDS widget has a bug when touching the card while the animation is still in motion
                        // //this bug is only present on back press.
                        // //disable touch for a second while the animation finishes

                        // setState(() {
                        //   ignoretouch = true;
                        // });
                        // sleep(Duration(seconds: 1));

                        // setState(() {
                        //   ignoretouch = false;
                        // });

                        // wordsfinished += 1;
                        // setState(() {
                        //   percentage = wordsfinished / words.length;
                        //   percentage = percentage.toDouble();
                        // });
                      },
                      onEnd: () {
                        print('end');
                        setState(() {
                          hasfinishedloading = false;
                        });
                        Navigator.pop(context);
                        //show stats page.
                        //how many words flagged
                        //ability to see flagged words
                        //ability to exit to main screen
                        //ability to restart
                      },
                      size: Size(
                        MediaQuery.of(context).size.width * 0.9,
                        MediaQuery.of(context).size.height * 0.6,
                      ),
                      cards: cards,
                    )
                  : CircularProgressIndicator()),
          Center(
            child: Text(
              "Swipe left or right to dismiss",
              style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontSize: 14),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Center(
              child: InkWell(
            child: Text(
              "View related sentences",
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              var lexemid_list =
                  json.decode(prefs.getString("lexemid_list") ?? "");
              if (lexemid_list
                  .containsKey(flashcard_words_list[wordsfinished])) {
                prefs.remove("relatedsentences_word");
                prefs.setString("relatedsentences_word",
                    flashcard_words_list[wordsfinished].toString() ?? " ");
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RelatedSentences()));
              } else {
                final snackBar =
                    SnackBar(content: Text('Not supported for custom words'));

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            },
          )),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _bottombuttons("previous", () {
                flashcardscontroller.back();
              }),
              // _bottombuttons("flag", () {}),
              _bottombuttons("next", () {
                flashcardscontroller.forward();
              })
            ],
          ),
        ],
      ),
    );
  }

  _bottombuttons(var text, VoidCallback onpressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: ElevatedButton(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.white)),
        onPressed: onpressed,
        child: Text(
          text,
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
