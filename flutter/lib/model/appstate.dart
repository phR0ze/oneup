import 'package:flutter/material.dart';
import 'package:oneup/ui/views/today.dart';
import 'user.dart';
import 'points.dart';
import 'category.dart';

class AppState extends ChangeNotifier {
  String adminPass = 'admin';
  bool isAdminAuthorized = true;
  Widget currentView = TodayView();

  var users = <User>[
    User(1, 'Harry', [
      Points(1, 1, 1, 2, 'Potions'),
      Points(2, 3, 1, 3, 'Transfiguration'),
      Points(3, 3, 1, 4, 'Charms'),
      Points(4, 4, 1, 5, 'Defense Against the Dark Arts'),
      Points(21, -8, 1, 5, 'Defense Against the Dark Arts'),
    ]),
    User(2, 'Ron', [
      Points(5, 1, 2, 2, 'Potions'),
      Points(6, 4, 2, 3, 'Transfiguration'),
      Points(7, 5, 2, 4, 'Charms'),
    ]),
    User(3, 'Hermione', [
      Points(10, 6, 3, 3, 'Transfiguration'),
      Points(11, 3, 3, 4, 'Charms'),
      Points(12, 3, 3, 5, 'Defense Against the Dark Arts'),
    ]),
    User(4, 'Snape', [
      Points(13, 3, 4, 2, 'Potions'),
      Points(14, 5, 4, 5, 'Defense Against the Dark Arts'),
    ]),
  ];

  var categories = <Category>[
    Category(1, 'Misc'), // Default category to containe uncategorized points
    Category(2, 'Potions'),
    Category(3, 'Transfiguration'),
    Category(4, 'Charms'),
    Category(5, 'Defense Against the Dark Arts'),
  ];

  // **********************************************************************************************
  // General methods
  // **********************************************************************************************

  // Set the current view
  void setCurrentView(Widget view) {
    this.currentView = view;
    notifyListeners();
  }

  // **********************************************************************************************
  // Admin methods
  // **********************************************************************************************

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

  // **********************************************************************************************
  // Points methods
  // **********************************************************************************************

  // Add points for the given user and category
  void addPoints(int userId, int categoryId, int value) {
    var user = users.firstWhere((x) => x.id == userId);
    var category = categories.firstWhere((x) => x.id == categoryId);
    user.points.add(Points(
      1,
      value,
      userId,
      categoryId,
      category.name,
    ));

    notifyListeners();
  }

  // **********************************************************************************************
  // User methods
  // **********************************************************************************************

  // Add user if it doesn't already exist
  //
  // @return false if it exists already
  bool addUser(User user) {
    if (users.any((x) => x.name == user.name)) {
      return false;
    }

    users.add(user);
    notifyListeners();
    return true;
  }

  // Update the given user in the data store
  bool updateUser(User user) {
    var i = users.indexWhere((x) => x.id == user.id);
    if (i == -1) {
      return false;
    }

    users[i] = user;
    notifyListeners();
    return true;
  }

  void removeUser(String name) {
    users.removeWhere((x) => x.name == name);
    notifyListeners();
  }

  // **********************************************************************************************
  // Category methods
  // **********************************************************************************************

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

  // Update the given category in the data store
  bool updateCategory(Category category) {
    var i = categories.indexWhere((x) => x.id == category.id);
    if (i == -1) {
      return false;
    }

    categories[i] = category;
    notifyListeners();
    return true;
  }


  // Remove category and associate any related points to the default category
  void removeCategory(String name) {

    // Don't allow removing the default category
    if (name == 'Misc') {
      return;
    }
    var misc = categories.firstWhere((x) => x.name == 'Misc');

    // Re-categories any points associated with the category to be removed with the default category
    var target = categories.firstWhere((x) => x.name == name);
    for (var user in users) {
      for (var point in user.points) {
        if (point.categoryId == target.id) {
          point.categoryId = misc.id;
        }
      }
    }

    categories.removeWhere((x) => x.name == name);
    notifyListeners();
  }
}