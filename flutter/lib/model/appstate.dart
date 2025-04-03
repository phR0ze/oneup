import 'package:flutter/material.dart';
import 'package:oneup/ui/views/today.dart';
import 'user.dart';
import 'points.dart';
import 'category.dart';

class AppState extends ChangeNotifier {
  String adminPass = 'admin';
  bool isAdminAuthorized = false;
  Widget currentView = TodayView();

  var users = <User>[
    User(1, 'Harry', [
      Points(1, 1, 1, 1, 'Potions'),
      Points(2, 3, 1, 2, 'Transfiguration'),
      Points(3, 3, 1, 3, 'Charms'),
      Points(4, 4, 1, 4, 'Defense Against the Dark Arts'),
    ]),
    User(2, 'Ron', [
      Points(5, 1, 2, 1, 'Potions'),
      Points(6, 4, 2, 2, 'Transfiguration'),
      Points(7, 5, 2, 3, 'Charms'),
    ]),
    User(3, 'Hermione', [
      Points(10, 6, 3, 2, 'Transfiguration'),
      Points(11, 3, 3, 3, 'Charms'),
      Points(12, 3, 3, 4, 'Defense Against the Dark Arts'),
    ]),
    User(4, 'Snape', [
      Points(13, 3, 4, 1, 'Potions'),
      Points(2, 5, 4, 4, 'Defense Against the Dark Arts'),
    ]),
  ];

  var categories = <Category>[
    Category(1, 'Potions'),
    Category(2, 'Transfiguration'),
    Category(3, 'Charms'),
    Category(4, 'Defense Against the Dark Arts'),
  ];

  // Authorize based on password
  void adminAuthorize(String password) {
    this.isAdminAuthorized = password == adminPass;
    notifyListeners();
  }

  // Remove admin authorization
  void adminDeauthorize() {
    this.isAdminAuthorized = false;
    notifyListeners();
  }

  // Update the admin password
  void updateAdminPassword(String password) {
    this.adminPass = password;
    notifyListeners();
  }

  // Set the current view
  void setCurrentView(Widget view) {
    this.currentView = view;
    notifyListeners();
  }

  // Add category if it doesn't already exist
  //
  // @return false if it exists already
  bool addCategory(String name) {
    if (categories.any((x) => x.name == name)) {
      return false;
    }

    var newCategory = Category(categories.length + 1, name);
    categories.add(newCategory);
    notifyListeners();
    return true;
  }

  void removeCategory(String name) {
    categories.removeWhere((x) => x.name == name);
    notifyListeners();
  }
}