import 'dart:async';

import 'package:PanayTranslator/drawer.dart';
import 'package:PanayTranslator/model/language.dart';
import 'package:flutter/material.dart';
import 'package:PanayTranslator/utilities/database.dart';

class Translator extends StatefulWidget {
  Translator({Key key, String title}) : super(key: key);
  @override
  _TranslatorState createState() => _TranslatorState();
}

class _TranslatorState extends State<Translator> {
  bool swapped;
  SQLiteDatabaseProvider db = SQLiteDatabaseProvider();

// Drop Down Menu for Language
  List<DropdownMenuItem<Language>> _dropdownMenuItems;

  // font size config:
  double languageBarSize = 16;
  double languageCardSize = 24;

  Language _selectedLanguage;

  final englishText = TextEditingController();
  final localText = TextEditingController();
  Map languages;
  Future<Map> getLanguages;

  void initState() {
    super.initState();
    swapped = false;
    getLanguages = getData();

    englishText.addListener(_englishTextListener);
    localText.addListener(_localTextTextListener);
  }

  Future<Map> getData() async {
    Map data = await db.getRegionLanguage();
    // Map regions = data['regions'];
    languages = data['languages'];
    print('Finished getting data');
    print(data);
    return languages;
  }

  @override
  void dispose() {
    localText.dispose();
    englishText.dispose();
    super.dispose();
  }

  clearTextFields() {
    localText.clear();
    englishText.clear();
  }

  _englishTextListener() async {
    String output = '';
    List result = [];
    String input = englishText.text.toLowerCase().trim();

    if (swapped) {
      result = await db.toLocal(input);
      if (result.isNotEmpty) {
        output = result[_selectedLanguage.languageID - 1].phrase;
      } else {
        output = '';
      }

      if (output != null) {
        setState(() {
          localText.value = TextEditingValue(text: output);
        });
      }
    }
  }

  _localTextTextListener() async {
    String output = '';
    List result = [];
    String input = localText.text.toLowerCase().trim();
    if (!swapped) {
      result = await db.toEnglish(input, _selectedLanguage.languageID);
      print(result);
      if (result.isNotEmpty) {
        output = result[0].phrase;
      } else {
        output = '';
      }
    }

    if (output != null) {
      setState(() {
        englishText.value = TextEditingValue(text: output);
      });
    }
  }

  Widget englishBar() {
    return Text(
      'English',
      style: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: languageBarSize,
      ),
    );
  }

  Widget regionLogo(String logo) {
    // avoid errors when logo is empty or null
    if (logo != null && logo.isNotEmpty) {
      return Image.asset(
        logo,
        height: 60,
        fit: BoxFit.fitHeight,
      );
    } else {
      return Container();
    }
  }

  List<DropdownMenuItem<Language>> buildDropDownMenuItems(Map listItems) {
    List<DropdownMenuItem<Language>> items = [];
    listItems.forEach((key, value) {
      if (value.language != 'English') {
        items.add(
          DropdownMenuItem(
            child: Row(
              children: [
                regionLogo(value.logo), // logo image widget
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                ),
                Container(
                  child: Text(
                    value.language,
                    overflow: TextOverflow.fade,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            value: value,
          ),
        );
      }
    });
    return items;
  }

  Widget localLanguagesBar() {
    languages.remove(0);
    return DropdownButtonHideUnderline(
      child: DropdownButton<Language>(
          isExpanded: true,
          selectedItemBuilder: (BuildContext context) {
            return languages.values.map<Widget>((language) {
              return Container(
                alignment: Alignment.center,
                child: Text(
                  language.language,
                ),
              );
            }).toList();
          },
          elevation: 9,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: languageBarSize,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).primaryColor,
          ),
          value: _selectedLanguage,
          items: _dropdownMenuItems,
          onChanged: (value) {
            setState(() {
              _selectedLanguage = value;
            });
          }),
    );
  }

  Widget languageOrientation(String position) {
    List<Widget> orientation = [];
    List<Widget> cards = [];
    if (swapped) {
      orientation = [englishBar(), localLanguagesBar()];
      cards = [
        englishCard(active: true),
        localCard(language: _selectedLanguage)
      ];
    } else {
      orientation = [localLanguagesBar(), englishBar()];
      cards = [
        localCard(language: _selectedLanguage, active: true),
        englishCard()
      ];
    }

    if (position == 'left') {
      return orientation[0];
    }
    if (position == 'right') {
      return orientation[1];
    }
    if (position == 'card1') {
      return cards[0];
    }
    if (position == 'card2') {
      return cards[1];
    }
    return Text('error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panay Translator'),
      ),
      drawer: MainDrawer(),
      body: FutureBuilder(
          future: getLanguages,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _dropdownMenuItems = buildDropDownMenuItems(snapshot.data);
              if (_selectedLanguage == null) {
                _selectedLanguage = _dropdownMenuItems[0].value;
                print(_selectedLanguage.language);
              }

              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    height: 45,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            child: languageOrientation('left'),
                          ),
                        ),
                        RaisedButton(
                          elevation: 0,
                          color: Theme.of(context)
                              .canvasColor, //transparent background color
                          shape: CircleBorder(),
                          onPressed: () {
                            setState(() {
                              swapped = !swapped;
                              clearTextFields();
                            });
                          },
                          child: Icon(Icons.swap_horiz,
                              size: 45, color: Theme.of(context).primaryColor),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            child: languageOrientation('right'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  languageOrientation('card1'),
                  languageOrientation('card2'),
                  RaisedButton(
                    onPressed: () {
                      // db.populateDatabase();
                      // db.getAll().then((value) => print(value));

                      // db.getLanguage('good morning');
                      // print(_languageList[1].languageID);
                      getData();
                    },
                  )
                ],
              );
            } else {
              return SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              );
            }
          }),
    );
  }

  Widget englishCard({bool active = false}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        color: !active
            ? Theme.of(context).primaryColor
            : Theme.of(context).accentColor,
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(5),
      child: Column(
        children: [
          // Text('English'),
          TextField(
            style: TextStyle(
              fontSize: languageCardSize,
              color: !active
                  ? Theme.of(context).accentColor
                  : Theme.of(context).primaryColor,
            ),
            controller: englishText,
            // onChanged: _onChangeHandler,
            enabled: active,
            maxLines: 6,
            minLines: !active
                ? 3
                : 1, // in-line if-else statement. if not active minLines = 3, else minLines = 1
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'English',
              hintStyle: TextStyle(
                fontSize: 16,
                color: !active ? Theme.of(context).accentColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget localCard({bool active = false, Language language}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        color: !active
            ? Theme.of(context).primaryColor
            : Theme.of(context).accentColor,
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(5),
      child: Column(
        children: [
          // Text(language.name),
          TextField(
            style: TextStyle(
              fontSize: languageCardSize,
              color: !active
                  ? Theme.of(context).accentColor
                  : Theme.of(context).primaryColor,
            ),
            enabled: active,
            controller: localText,
            // onChanged: _onChangeHandler,
            maxLines: 6,
            minLines: !active ? 3 : 1,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: language.language,
              hintStyle: TextStyle(
                fontSize: 16,
                color: !active ? Theme.of(context).accentColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
