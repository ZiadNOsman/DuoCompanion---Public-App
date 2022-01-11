import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert' show utf8;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:expandable/expandable.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

class RelatedSentences extends StatefulWidget {
  RelatedSentences({Key? key}) : super(key: key);

  @override
  _RelatedSentencesState createState() => _RelatedSentencesState();
}

class _RelatedSentencesState extends State<RelatedSentences> {
  @override
  void initState() {
    // TODO: implement initState
    textController.addListener(_searchingfunc);

    super.initState();
    getdata();
  }

  var alternative_forms_list = [];
  var finishedinitstate = false;
  var searching = false;
  var static_alternative_forms_list = [];
  TextEditingController textController = TextEditingController();
  _searchingfunc() {
    var currtext = textController.text;
    var temp_words_list = [];
    for (var word_info in static_alternative_forms_list) {
      if (word_info["text"].toLowerCase().contains(currtext) ||
          word_info["translation_text"].toLowerCase().contains(currtext)) {
        temp_words_list.add(word_info);
      }
    }
    setState(() {
      alternative_forms_list = temp_words_list;
    });
  }

  getdata() async {
    setState(() {
      alternative_forms_list = [];
      finishedinitstate = false;
    });
    final prefs = await SharedPreferences.getInstance();
    var relatedsentences_word = prefs.getString("relatedsentences_word") ?? " ";
    var lexemid_list = json.decode(prefs.getString("lexemid_list") ?? "");
    var word_lexiom_id = lexemid_list[relatedsentences_word[0].toLowerCase() +
        relatedsentences_word.substring(1)];

    var alternative_forms_url =
        "https://www.duolingo.com/api/1/dictionary_page?lexeme_id=";
    alternative_forms_url += word_lexiom_id;
    final alternative_forms_api =
        await http.get(Uri.parse(alternative_forms_url));

    if (alternative_forms_api.statusCode == 200) {
      var all_alternative_forms =
          jsonDecode(alternative_forms_api.body)["alternative_forms"] ?? [];

      for (var wordjson in all_alternative_forms) {
        alternative_forms_list.add({
          "text": wordjson['text'] ?? "",
          "translation_text": wordjson["translation_text"] ?? "",
          "tts": wordjson["tts"],
          "word": wordjson["word"] ?? "",
          "discussion": wordjson["discussion"]
        });
      }
      static_alternative_forms_list = alternative_forms_list;
      // print(alternative_forms_list);
    }
    setState(() {
      finishedinitstate = true;
    });
  }

  @override
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
                hintText: "Search",
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
              child: alternative_forms_list.length > 0
                  ? ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        for (var sentence_info in alternative_forms_list)
                          makenewcategory(context, sentence_info)
                      ],
                    )
                  : Text("No related sentences"),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }

  //fuunction called to make new categories. it takes as arguments the title of the category and the children of the category
  //fuunction called to make new categories. it takes as arguments the title of the category and the children of the category
  makenewcategory(BuildContext context, sentence_info) {
    return Container(
      decoration:
          BoxDecoration(border: Border.all(width: 0.05, color: Colors.grey)),
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
                        sentence_info["text"] ?? "",
                        style: TextStyle(
                          fontSize: 18,
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
                              alignment: Alignment.topLeft,
                              child: Text(
                                '"' + sentence_info['translation_text'] + '"',
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
                                    sentence_info["discussion"] != null
                                        ? Container(
                                            alignment: Alignment.topRight,
                                            child: InkWell(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  "View Discussion (${sentence_info["discussion"]["num_comments"]} comments)",
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                              onTap: () async {
                                                var discussion_url = Uri.parse(
                                                    "https://duolingo.com" +
                                                        sentence_info[
                                                                "discussion"]
                                                            ["url"]);
                                                await canLaunch(discussion_url
                                                        .toString())
                                                    ? await launch(
                                                        discussion_url
                                                            .toString())
                                                    : throw 'Could not launch $discussion_url';
                                              },
                                            ),
                                          )
                                        : Container(),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    ElevatedButton(
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18.0),
                                                  side: BorderSide(
                                                      color: Colors.blue))),
                                          elevation:
                                              MaterialStateProperty.all<double>(
                                                  0),
                                          shadowColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.white10),
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(Colors.white),
                                          fixedSize: MaterialStateProperty.all<Size?>(Size(55, 55))),
                                      child: Icon(
                                        Icons.volume_up_outlined,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () async {
                                        if (sentence_info['tts'] != null &&
                                            sentence_info['tts'] != "null") {
                                          AudioPlayer player =
                                              new AudioPlayer();

                                          player.play(sentence_info['tts']);
                                        } else {
                                          final snackBar = SnackBar(
                                              content:
                                                  Text('No audio available'));

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }
                                      },
                                    )
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
