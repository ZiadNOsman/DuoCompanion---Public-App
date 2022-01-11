import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:convert' show utf8;
import 'dart:convert';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'isloggedin.dart';
import 'package:flutter/services.dart';
import 'package:sortedmap/sortedmap.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.orange, // navigation bar color
    statusBarColor: Colors.orange, // status bar color
  ));
  runApp(MaterialApp(
    home: Isloggedin(),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    identifier.addListener(reseterrorbutton);
    password.addListener(reseterrorbutton);
    super.initState();
    //isloggedin();
  }

  var header;
  var wordslearned;
  var syncstatus = "";
  var hidepassword = true;
  var errorloggingin = false;
  var issyncing = false;
  final RoundedLoadingButtonController _syncwords =
      RoundedLoadingButtonController();
  TextEditingController identifier = new TextEditingController();
  TextEditingController password = new TextEditingController();

  changesyncstatus(String newstatus) async {
    setState(() {
      syncstatus = newstatus;
    });
  }

  @override
  reseterrorbutton() {
    setState(() {
      if (errorloggingin == true) {
        issyncing = false;

        _syncwords.reset();
      }
    });
  }

  nbofwordslearned(var valueMap) async {
    setState(() {
      var temp = valueMap["vocab_overview"];
      wordslearned = temp.length;
    });
  }

  isloggedin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("identifier") != null &&
        prefs.getString("password") != null) {
      print("ur logged in");
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Homepage()));
    }
  }

  var categories = new Map();
  //final LocalStorage storage = new LocalStorage("duolearnedword.json");

  getduoInfo() async {
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
      changesyncstatus("Could not authenticate");
      prefs.remove('identifier');
      prefs.remove('password');

      setState(() {
        errorloggingin = true;
        issyncing = false;
        _syncwords.error();
      });

      throw Exception('Failed to post');
    }

    changesyncstatus("Fetching languages");

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
    } else {
      changesyncstatus("Could not fetch languages");
      prefs.remove('identifier');
      prefs.remove('password');
      setState(() {
        errorloggingin = true;
        issyncing = false;
        _syncwords.error();
      });
      throw Exception('Failed to post');
    }
    changesyncstatus("Fetching words");

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
            translationapiissues = true;

            changesyncstatus("Could not fetch translations");
            prefs.remove('identifier');
            prefs.remove('password');
            setState(() {
              errorloggingin = true;
              issyncing = false;
              _syncwords.error();
            });
            throw Exception('Failed to post');
          }

          wordcounter = 0;
        }
      }
      prefs.remove("words_strength_map");
      prefs.setString("words_strength_map", jsonEncode(words_strength_map));

      prefs.remove("lexemid_list");
      prefs.setString("lexemid_list", json.encode(wordswithlexemid));
      //storage.setItem("categories", categories);
      prefs.remove("pronounciations");
      prefs.setString("pronounciations", json.encode(pronounciations));

      prefs.remove("categories");
      prefs.setString("categories", json.encode(categories));
      print(unsegmentedtranslations);
      if (translationapiissues == false) {
        var missingvals = false;
        var fixtransapi = "https://d2.duolingo.com/api/1/dictionary/hints";
        fixtransapi += "/" +
            valueMap["learning_language"] +
            "/" +
            valueMap["from_language"] +
            '?tokens=' +
            "[";
        var gottranslations = unsegmentedtranslations;
        changesyncstatus("Fixing translations");

        var wordstofix = [];
        for (var checknulltrans in gottranslations.keys) {
          // print(gottranslations[checknulltrans].runtimeType);
          if (gottranslations[checknulltrans].length == 0) {
            missingvals = true;
            var capitalizedword =
                checknulltrans[0].toUpperCase() + checknulltrans.substring(1);
            //gottranslations.remove(checknulltrans);
            //create new map of the capitalized words
            // get word translations by re-calling the api on the new map
            //merge the old and new maps

            //fixtransapi += '"' + capitalizedword + '",';
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
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Homepage()));
        } else {
          //if there are no missing values, directly save the translated words

          prefs.setString("translations", jsonEncode(unsegmentedtranslations));
        }

        changesyncstatus("");
      } else {
        changesyncstatus("Could not fix translations");
        prefs.remove('identifier');
        prefs.remove('password');
        setState(() {
          errorloggingin = true;
          issyncing = false;
          _syncwords.error();
        });

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Homepage()));
        throw Exception('Failed to post');
      }

      _syncwords.success();
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Homepage()));
      // print(resp2.body.runtimeType);
    } else {
      //even if its not authenticated, the status code is still 200
      //this condition never runs
      //find another way to determine if request is false
      prefs.remove('identifier');
      prefs.remove('password');
      setState(() {
        errorloggingin = true;
        issyncing = false;
        _syncwords.error();
      });
      throw Exception('Failed to post');
    }
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async => exit(0),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 45,
          leading: Container(),
          title: Text(
            "Login",
            style: TextStyle(fontFamily: "feather", color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          shadowColor: Colors.grey[50],
        ),
        body: Container(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          width: double.infinity,
          height: double.infinity,

          padding: EdgeInsets.all(30),
          child: SingleChildScrollView(
            child: Container(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
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
                    height: 100,
                  ),
                  TextField(
                    cursorColor: Colors.blue,
                    style: TextStyle(color: Colors.black),
                    enabled: !issyncing,
                    controller: identifier,
                    decoration: InputDecoration(
                        hintText: "Duolingo Username",
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
                  SizedBox(height: 10),
                  TextField(
                    cursorColor: Colors.blue,
                    style: TextStyle(color: Colors.black),
                    enabled: !issyncing,
                    controller: password,
                    obscureText: hidepassword,
                    decoration: InputDecoration(
                        suffixIcon: password.text == ""
                            ? null
                            : IconButton(
                                onPressed: () async {
                                  setState(() {
                                    hidepassword = !hidepassword;
                                  });
                                },
                                icon: Icon(
                                  hidepassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black,
                                )),
                        hintText: "Duolingo password",
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
                  SizedBox(height: 30),
                  Container(
                    child: RoundedLoadingButton(
                      height: 55,
                      color: Colors.blue,
                      successColor: Colors.green,
                      errorColor: Colors.red,
                      borderRadius: 10,
                      child: Text('Login',
                          style: TextStyle(
                              fontFamily: "feather",
                              color: Colors.white,
                              fontSize: 20)),
                      controller: _syncwords,
                      onPressed: () async {
                        //first make sure the login identifier is a username, not an email.
                        issyncing = true;

                        print("sync pressed");
                        bool emailValid = RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(identifier.text);
                        if (emailValid) {
                          changesyncstatus(
                              "please use a username, not an email");
                          setState(() {
                            print("you put an email");
                            errorloggingin = true;
                            issyncing = false;
                            _syncwords.error();
                          });
                        } else {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          prefs.setString("identifier", identifier.text);
                          prefs.setString("password", password.text);
                          setState(() {
                            _syncwords.start();
                            errorloggingin = false;
                          });

                          getduoInfo();
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Text(
                      syncstatus,
                      style: TextStyle(
                          color: errorloggingin ? Colors.red : Colors.grey[400],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
