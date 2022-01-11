import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'setup.dart';
// import 'package:localstorage/localstorage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mywords.dart';
import 'dictionary.dart';
import 'grammar_setup.dart';
import 'package:sortedmap/sortedmap.dart';
import 'customskills.dart';

class Homepage extends StatefulWidget {
  Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  getdata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //wordslearned = prefs.getString()
    var testvar = prefs.getString("information");
    Map valueMap = json.decode(testvar ?? "");
    nbofwordslearned(valueMap);
  }

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    isloggedin();

    getdata();
  }

  var header;
  var wordslearned;
  var syncstatus = "";
  var username = '';
  var drawerheader_learninglang = "";
  var drawerheader_fromlang = "";
  var finishedinitstate = false;
  var loading_changelanguage = false;
  var available_flags = {
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

  isloggedin() async {
    setState(() {
      finishedinitstate = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString("translations"));
    if (prefs.getString("identifier") == null ||
        prefs.getString("password") == null) {
      print("not logged in");

      Navigator.pop(context);
    } else {
      setState(() {
        drawerheader_learninglang =
            jsonDecode(prefs.getString("information").toString())[
                    "learning_language"] ??
                "";
        drawerheader_fromlang = jsonDecode(
                prefs.getString("information").toString())["from_language"] ??
            "";

        username = prefs.getString("identifier") ?? "";
      });
    }
    setState(() {
      finishedinitstate = true;
    });
  }

  changesyncstatus(String newstatus) async {
    setState(() {
      syncstatus = newstatus;
    });
  }

  var categories = new Map();
  //final LocalStorage storage = new LocalStorage("duolearnedword.json");
  final RoundedLoadingButtonController _syncwords =
      RoundedLoadingButtonController();

  nbofwordslearned(var valueMap) async {
    setState(() {
      var temp = valueMap["vocab_overview"];
      wordslearned = temp.length;
    });
  }

  getduoInfo(
      {bool changelanguage =
          false, //parameter changed to true when we call this function when changing the language
      String changedlang = ""}) async {
    changesyncstatus("Authenticating");
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await http.post(
      Uri.parse('https://www.duolingo.com/2017-06-30/login?fields='),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'identifier': prefs.getString("identifier") ?? "",
        'password': prefs.getString("password") ?? "",
      }),
    );

    if (response.statusCode == 200) {
      changesyncstatus("Authenticated!");

      header = response.headers;
    } else {
      _syncwords.error();
      setState(() {
        loading_changelanguage = false;
      });
      final snackBar = SnackBar(
        content: Text("Could not authenticate"),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      changesyncstatus("Could not authenticate");

      throw Exception('Failed to post');
    }

    if (changelanguage == true) {
      //remove the old categories
      categories = {};

      final changelangapi = await http.post(
        Uri.parse(
            'https://www.duolingo.com/switch_language?learning_language=$changedlang'),
        headers: {
          HttpHeaders.authorizationHeader: header['jwt'],
        },
      );
      if (changelangapi.statusCode == 200) {
//change display flag and drawer header info to reflect the new language

        // AwesomeDialog(
        //   //dismissOnTouchOutside: false,
        //   context: context,
        //   dialogType: DialogType.INFO,
        //   animType: AnimType.BOTTOMSLIDE,
        //   title: "changing language",
        //   desc: "changing to " + changedlang,
        //   body: CircularProgressIndicator(),
        //   //btnOkOnPress: () {},
        // )..show();
      } else {
        setState(() {
          loading_changelanguage = false;
        });
        final snackBar = SnackBar(
          content: Text("Could not change to desired language"),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        // AwesomeDialog(
        //   // dismissOnTouchOutside: false,
        //   context: context,
        //   dialogType: DialogType.ERROR,
        //   animType: AnimType.BOTTOMSLIDE,
        //   title: "could not change language",

        //   btnOkOnPress: () {},
        // )..show();
      }
    }

    changesyncstatus("Fetching words");

    var getlangsurl = "https://www.duolingo.com/users/";
    getlangsurl += prefs.getString("identifier") ?? "";

    final getlearninglangs = await http.get(Uri.parse(getlangsurl), headers: {
      HttpHeaders.authorizationHeader: header['jwt'],
    });
    if (getlearninglangs.statusCode == 200) {
      var learninglanguages = {};
      var alllanguages = json.decode(getlearninglangs.body)['languages'];

      for (var language in alllanguages) {
        if (language["learning"]) {
          learninglanguages[language["language"]] = language["language_string"];
        }
      }
      prefs.remove("learning_languages");
      prefs.setString("learning_languages", jsonEncode(learninglanguages));
    }

    final resp2 = await http.get(
        Uri.parse("https://www.duolingo.com/vocabulary/overview"),
        headers: {
          HttpHeaders.authorizationHeader: header['jwt'],
        });
    if (resp2.statusCode == 200) {
      //print(resp2.body);

      //storage.setItem("information", resp2.body);

      //remove old data
      prefs.remove("information");
      prefs.remove("categories");
      prefs.remove("translations");

      //set new data
      prefs.setString("information", resp2.body);

      var testvar = prefs.getString("information");
      Map valueMap = json.decode(testvar ?? "");

//this will change the displayed flag and information in the drawerheader. useful when we change languages
      setState(() {
        drawerheader_fromlang = valueMap["from_language"] ?? "";
        drawerheader_learninglang = valueMap["learning_language"] ?? "";
      });
      nbofwordslearned(valueMap);
      var vocab = valueMap['vocab_overview'];

      var tempapi = "https://d2.duolingo.com/api/1/dictionary/hints";
      tempapi += "/" +
          valueMap["learning_language"] +
          "/" +
          valueMap["from_language"] +
          '?tokens=' +
          "[";

      var wordcounter = 0;
      var totalwordslooped = 0;
      var unsegmentedtranslations = {};
      var translationapiissues = false;
      var pronounciations = {};
      var wordswithlexemid = {};
      var words_strength_map = SortedMap(Ordering.byValue());
      for (var i = 0; i < vocab.length; i++) {
        wordcounter += 1;
        totalwordslooped += 1;
        var skillname = vocab[i]['skill_url_title'];
        var word = vocab[i]['word_string'];
        var strength = vocab[i]['strength'];
        words_strength_map.putIfAbsent(word, () => strength);
        pronounciations[word] = vocab[i]['normalized_string'];
        wordswithlexemid[word] = vocab[i]["lexeme_id"];
        tempapi += '"' + word + '",';

        if (categories.containsKey(skillname)) {
          categories[skillname].add(word);

          //categories[skillname][word].add("");
        } else {
          categories[skillname] = [word];
        }

        changesyncstatus("Fetching translations");

        if (wordcounter > 500 || totalwordslooped == wordslearned) {
          //call the api and save inside a map
          tempapi = tempapi.substring(0, tempapi.length - 1);
          tempapi += "]";
          final translateapi = await http.get(Uri.parse(tempapi), headers: {
            HttpHeaders.authorizationHeader: header['jwt'],
          });

          if (translateapi.statusCode == 200) {
            //call the api
            unsegmentedtranslations.addAll(jsonDecode(translateapi.body));
            //reset the words list
            tempapi = "https://d2.duolingo.com/api/1/dictionary/hints";
            tempapi += "/" +
                valueMap["learning_language"] +
                "/" +
                valueMap["from_language"] +
                '?tokens=' +
                "[";
          } else {
            _syncwords.error();
            translationapiissues = true;
            changesyncstatus("Could not retrieve");
            setState(() {
              loading_changelanguage = false;
            });
            final snackBar = SnackBar(
              content: Text("Could not change to desired language"),
              behavior: SnackBarBehavior.floating,
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);

            throw Exception('Failed to post');
          }

          wordcounter = 0;
        }
      }
      prefs.remove("words_strength_map");
      prefs.setString("words_strength_map", jsonEncode(words_strength_map));
      // print(words_strength_map);
      prefs.remove("lexemid_list");
      prefs.setString("lexemid_list", json.encode(wordswithlexemid));
      //storage.setItem("categories", categories);
      print(pronounciations);
      prefs.remove("pronounciations");

      prefs.setString("pronounciations", json.encode(pronounciations));

      prefs.remove("categories");
      prefs.setString("categories", json.encode(categories));
      print(unsegmentedtranslations);

      if (translationapiissues == false) {
        var wordstoremovefrommap = [];
        var missingvals = false;
        var fixtransapi = "https://d2.duolingo.com/api/1/dictionary/hints";
        fixtransapi += "/" +
            valueMap["learning_language"] +
            "/" +
            valueMap["from_language"] +
            '?tokens=' +
            "[";
        var gottranslations = unsegmentedtranslations;

        var wordstofix = [];

        changesyncstatus("Fixing translations");
        for (var checknulltrans in gottranslations.keys) {
          // print(gottranslations[checknulltrans].runtimeType);
          if (gottranslations[checknulltrans].length == 0) {
            missingvals = true;
            var capitalizedword =
                checknulltrans[0].toUpperCase() + checknulltrans.substring(1);
            wordstoremovefrommap.add(checknulltrans);
            //gottranslations.remove(checknulltrans);
            //create new map of the capitalized words
            // get word translations by re-calling the api on the new map
            //merge the old and new maps

            // fixtransapi += '"' + capitalizedword + '",';
            wordstofix.add(capitalizedword);
          }
        }

        if (missingvals == true) {
          //segment the word to fix into 500 words because the duolingo api rejects the call if there are too many words
          var wordcounter_fix = 0;
          var totalwordslooped_fix = 0;
          var temp_fixtransapi = fixtransapi;

          for (var wordtofix in wordstofix) {
            wordcounter_fix += 1;
            totalwordslooped_fix += 1;
            temp_fixtransapi += '"' + wordtofix + '",';

            if (wordcounter_fix > 500 ||
                totalwordslooped_fix == wordstofix.length) {
              //call the temp api
              temp_fixtransapi =
                  temp_fixtransapi.substring(0, temp_fixtransapi.length - 1);
              temp_fixtransapi += "]";

              final translateapi2 =
                  await http.get(Uri.parse(temp_fixtransapi), headers: {
                HttpHeaders.authorizationHeader: header['jwt'],
              });
              //reset the api words
              temp_fixtransapi = fixtransapi;
              //reset word count
              wordcounter_fix = 0;

              if (translateapi2.statusCode == 200) {
                var capitalizedMap = jsonDecode(translateapi2.body);

                var translationMap = unsegmentedtranslations;

                //merge the two maps
                var alltranslations = {};
                alltranslations.addAll(capitalizedMap);
                alltranslations.addAll(translationMap);
                //remove words that are still with missing values
                //these words are likely composite words or derivative words
                alltranslations.removeWhere((key, value) => value.length == 0);

                //add the new words to the map of original words with translations
                unsegmentedtranslations = alltranslations;
                prefs.setString("translations", json.encode(alltranslations));
              }
            }
          }
        } else {
          //if there are no missing values, directly save the translated words

          prefs.setString("translations", jsonEncode(unsegmentedtranslations));
        }

        changesyncstatus("");
      } else {
        _syncwords.error();
        changesyncstatus("Could not retrieve");
        setState(() {
          loading_changelanguage = false;
        });
        final snackBar = SnackBar(
          content: Text("Could not change to desired language"),
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        throw Exception('Failed to post');
      }
      if (changelanguage == false) {
        _syncwords.success();
      } else {
        //success message when calling the change language api
        setState(() {
          loading_changelanguage = false;
        });
        final snackBar = SnackBar(
          content: Text("Language changed succesfully"),
          behavior: SnackBarBehavior.floating,
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      // print(resp2.body.runtimeType);
    } else {
      //even if its not authenticated, the status code is still 200
      //this condition never runs
      //find another way to determine if request is false
      _syncwords.error();
      setState(() {
        loading_changelanguage = false;
      });
      final snackBar = SnackBar(
        content: Text("Could not change to desired language"),
        behavior: SnackBarBehavior.floating,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      changesyncstatus("Could not retrieve");

      throw Exception('Failed to post');
    }
  }

  Future<Map> getlearninglanguages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var learningmap;
    learningmap = jsonDecode(prefs.getString("learning_languages") ?? "");
    return learningmap;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return new WillPopScope(
      onWillPop: () async =>
          exit(0), //prevent pressing the back button to go back by a page
      child: Scaffold(
          backgroundColor: Colors.white,
          drawer: Drawer(
              child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Container(
                      // width: MediaQuery.of(context).size.width,
                      // color: Colors.green[600],
                      padding: EdgeInsets.only(top: 0, left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Settings",
                              style: TextStyle(
                                  fontSize: 35, fontWeight: FontWeight.bold)),
                          Text(
                            username,
                            style: TextStyle(fontSize: 20),
                          ),
                          Text("Learning: " + drawerheader_learninglang ?? ""),
                          Text("From: " + drawerheader_fromlang ?? ""),
                        ],
                      )
                      //         FittedBox(
                      //   // width: MediaQuery.of(context).size.width,
                      //   child: Image.asset(
                      //       "assets/green_DC_icon (2)_drawer_header.png"),
                      // )
                      ) //Text('Drawer Header'),
                  ),
              SizedBox(height: 15),
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Mywords()));
                },
                child: Container(
                  height: 40,
                  padding: EdgeInsets.only(left: 15),
                  child: Text(
                    "\u{1F453} My words",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 15),
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Dictionary()));
                },
                child: Container(
                  height: 40,
                  padding: EdgeInsets.only(left: 15),
                  child: Text(
                    "\u{1F4AC} Dictionary",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 15),
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CustomSkills()));
                },
                child: Container(
                  height: 40,
                  padding: EdgeInsets.only(left: 15),
                  child: Text(
                    "\u{270D} Custom skills",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // InkWell(
              //   onTap: () {
              //     Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (context) => Changelanguage()));
              //   },
              //   child: Container(
              //     height: 40,
              //     padding: EdgeInsets.only(left: 15),
              //     child: Text(
              //       "\u{1F202} Change language",
              //       style: TextStyle(fontSize: 20),
              //     ),
              //   ),
              // ),
              SizedBox(height: 30),
              Container(
                child: RoundedLoadingButton(
                  color: Colors.green[600],
                  successColor: Colors.green,
                  errorColor: Colors.red,
                  borderRadius: 10,
                  child: Text('Sync words',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  controller: _syncwords,
                  onPressed: getduoInfo,
                ),
              ),
              SizedBox(height: 15),
              Center(
                child: Text(
                  syncstatus,
                  style: TextStyle(
                      color: Colors.grey[400], fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 15),
              Divider(),
              Container(
                alignment: Alignment.bottomCenter,
                child: Container(
                    width: double.infinity,
                    child: TextButton(
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        onPressed: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          prefs.remove('identifier');
                          prefs.remove('password');
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MyHomePage(
                                        title: "Login",
                                      )));
                        })),
              )
            ],
          )),
          appBar: AppBar(
            toolbarHeight: 45,
            title: Text(
              "Home",
              style: TextStyle(fontFamily: "feather", color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            shadowColor: Colors.grey[50],
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                  child: Column(
                children: [
                  Container(
                    alignment: Alignment.topRight,
                    child: loading_changelanguage
                        ? Container(
                            margin: EdgeInsets.only(top: 30, right: 30),
                            child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        side: BorderSide(color: Colors.white))),
                                elevation: MaterialStateProperty.all<double>(0),
                                shadowColor: MaterialStateProperty.all<Color>(
                                    Colors.white10),
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                                fixedSize: MaterialStateProperty.all<Size?>(
                                    Size(90, 90))),
                            child: finishedinitstate
                                ? available_flags
                                        .containsKey(drawerheader_learninglang)
                                    ? Image.asset(
                                        "assets/flags/$drawerheader_learninglang.png",
                                        width: 40,
                                        height: 40,
                                      )
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                              border: Border.all()),
                                          child: Text(
                                            "language",
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Container(
                                      padding: EdgeInsets.all(20),
                                      decoration:
                                          BoxDecoration(border: Border.all()),
                                      child: Text(
                                        "language",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                            onPressed: () {
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    height: 200,
                                    color: Colors.white,
                                    child: Center(
                                        child: FutureBuilder(
                                      builder: (ctx, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          // If we got an error
                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                '${snapshot.error} occured',
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            );
                                          } else if (snapshot.hasData) {
                                            // Extracting data from snapshot object
                                            final data = snapshot.data ?? {};
                                            var learninglangs;
                                            if (data != null) {
                                              learninglangs = data;
                                            } else {
                                              learninglangs = {};
                                            }

                                            return ListView(
                                              padding: EdgeInsets.all(20),
                                              scrollDirection: Axis.horizontal,
                                              children: [
                                                for (var learning_lang
                                                    in learninglangs.keys)
                                                  InkWell(
                                                    onTap: () async {
                                                      if (loading_changelanguage !=
                                                          true) {
                                                        if (learning_lang ==
                                                            drawerheader_learninglang) {
                                                          final snackBar =
                                                              SnackBar(
                                                            content: Text(
                                                              "learning language already set to " +
                                                                  learninglangs[
                                                                      learning_lang],
                                                            ),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                          );
                                                          //snackbar does not show on top of bottom sheet so we need to pop it to make the snackbar show
                                                          Navigator.pop(
                                                              context);

                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  snackBar);
                                                          // AwesomeDialog(
                                                          //     context: context,
                                                          //     btnOkOnPress: () {},
                                                          //     title:
                                                          //         "Language not changed",
                                                          //     desc:
                                                          //         "learning language already set to " +
                                                          //             learninglangs[
                                                          //                 learning_lang])
                                                          // ..show();
                                                        } else {
                                                          setState(() {
                                                            loading_changelanguage =
                                                                true;
                                                          });

                                                          getduoInfo(
                                                              changelanguage:
                                                                  true,
                                                              changedlang:
                                                                  learning_lang);

                                                          final snackBar =
                                                              SnackBar(
                                                            content: Text(
                                                                'Changing learning language to ' +
                                                                    learninglangs[
                                                                        learning_lang]),
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                          );

                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  snackBar);
                                                          Navigator.pop(
                                                              context);
                                                        }
                                                      } else {
                                                        final snackBar =
                                                            SnackBar(
                                                          content: Text(
                                                              "Still changing language, please wait"),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        );

                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                snackBar);
                                                        Navigator.pop(context);
                                                      }
                                                      print("tapped " +
                                                          learninglangs[
                                                              learning_lang]);
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          left: 7, right: 7),
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.2,
                                                      width: 170,
                                                      padding: EdgeInsets.only(
                                                          left: 15,
                                                          right: 15,
                                                          top: 15),
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              width: 3,
                                                              color: Colors
                                                                          .grey[
                                                                      200] ??
                                                                  Colors.grey),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15)),
                                                      child: Column(
                                                        children: [
                                                          available_flags
                                                                  .containsKey(
                                                                      learning_lang)
                                                              ? Image.asset(
                                                                  "assets/flags/$learning_lang.png",
                                                                )
                                                              : Image.asset(
                                                                  "assets/blue_DC_icon (1).png",
                                                                  width: 30,
                                                                  height: 30,
                                                                ),
                                                          SizedBox(
                                                            height: 5,
                                                          ),
                                                          FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                              learninglangs[
                                                                  learning_lang],
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      "feather"),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          }
                                        }

                                        // Displaying LoadingSpinner to indicate waiting state
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                      future: getlearninglanguages(),
                                    )),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Duo",
                      style: TextStyle(
                          fontFamily: "feather",
                          fontSize: 80,
                          color: Colors.black),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Companion",
                      style: TextStyle(
                          fontFamily: "feather",
                          fontSize: 50,
                          color: Colors.black),
                    ),
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: Offset(3, 5), // changes position of shadow
                          ),
                        ]),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Setup()));
                      },
                      child: Text("Targeted practice",
                          style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          fixedSize: Size(300, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.lightGreenAccent[900] ??
                                Colors.green.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: Offset(3, 5), // changes position of shadow
                          ),
                        ]),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GrammarSetup()));
                      },
                      child: Text(
                        "Grammar practice",
                        style: TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                          primary: Colors.lightGreenAccent[700],
                          fixedSize: Size(300, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  Container(
                      width: 300,
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.amber),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 2,
                              // changes position of shadow
                            ),
                          ]),
                      child: Center(
                        child: wordslearned == null
                            ? Text("Please re-sync",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ))
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  wordslearned.toString() + " Words",
                                  style: TextStyle(
                                      fontSize: 30, fontFamily: "feather"),
                                ),
                              ),
                      )),
                ],
              )),
            ],
          )),
    );
  }
}
