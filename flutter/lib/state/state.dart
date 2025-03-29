import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'model/user.dart';

class AppState extends ChangeNotifier {
  var favorites = <WordPair>[];
  var users = <User>[
    User(1, 'Harry', 4),
    User(2, 'Ron', 5),
    User(3, 'Hermione', 10),
  ];

  // Add a user to the DB
  // void addUser(String name) {
  //   var id = Random().nextInt(1000);
  //   users.add(User(id, name));

  //   notifyListeners();
  // }
}