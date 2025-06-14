import 'package:flutter/material.dart';
import '../model/user.dart';
import '../ui/views/range.dart';
import 'user_old.dart';
import 'points_old.dart';
import 'category_old.dart';
import '../providers/api.dart';

class AppState extends ChangeNotifier {
  final Api _api = Api();

  // old
  // **********************************************************************************************
  String adminPass = 'admin';
  String apiAddress = '';
  String apiToken = '';
  Widget currentView = const RangeView(range: Range.today);

  var users = <UserOld>[
    UserOld(1, 'Harry', [
      PointsOld(1, 1, 1, 2, 'Potions'),
      PointsOld(2, 3, 1, 3, 'Transfiguration'),
      PointsOld(3, 3, 1, 4, 'Charms'),
      PointsOld(4, 4, 1, 5, 'Defense Against the Dark Arts'),
      PointsOld(21, -8, 1, 5, 'Defense Against the Dark Arts'),
    ]),
    UserOld(2, 'Ron', [
      PointsOld(5, 1, 2, 2, 'Potions'),
      PointsOld(6, 4, 2, 3, 'Transfiguration'),
      PointsOld(7, 5, 2, 4, 'Charms'),
    ]),
    UserOld(3, 'Hermione', [
      PointsOld(10, 6, 3, 3, 'Transfiguration'),
      PointsOld(11, 3, 3, 4, 'Charms'),
      PointsOld(12, 3, 3, 5, 'Defense Against the Dark Arts'),
    ]),
    UserOld(4, 'Snape', [
      PointsOld(13, 3, 4, 2, 'Potions'),
      PointsOld(14, 5, 4, 5, 'Defense Against the Dark Arts'),
    ]),
  ];

  var categories = <CategoryOld>[
    CategoryOld(1, 'Misc'), // Default category to containe uncategorized points
    CategoryOld(2, 'Potions'),
    CategoryOld(3, 'Transfiguration'),
    CategoryOld(4, 'Charms'),
    CategoryOld(5, 'Defense Against the Dark Arts'),
  ];

  // Set the current view
  void setCurrentView(Widget view) {
    this.currentView = view;
    notifyListeners();
  }

  // **********************************************************************************************
  // Admin methods
  //
  // TODO: fix this
  // * Assuming any logged in user is an admin
  // * Assuming there is only one admin user
  // **********************************************************************************************

  // Check if the user is authorized
  bool isAdminAuthorized() {
    return _api.isAdminAuthorized();
  }

  // Deauthorize the user
  void deauthorize() {
    _api.deauthorize();
    notifyListeners();
  }

  // Login to the API
  Future<void> login(String? handle, String password) async {
    await _api.login(handle: handle ?? "admin", password: password);
    notifyListeners();
  }

  // Update the admin password
  void updateAdminPassword(String password) {
    this.adminPass = password;
    notifyListeners();
  }

  // **********************************************************************************************
  // User methods
  // **********************************************************************************************

  // Get the users from the API
  Future<List<User>> getUsers() async {
    return _api.getUsers();
  }

  // Add a user
  Future<void> addUser(String username, String email) async {
    await _api.createUser(username: username, email: email);
    notifyListeners();
  }

  // Update the given user in the data store
  Future<void> updateUser(int id, String username, String email) async {
    await _api.updateUser(id, username: username, email: email);
    notifyListeners();
  }

  Future<void> removeUser(int id) async {
    await _api.deleteUser(id);
    notifyListeners();
  }

  // **********************************************************************************************
  // API methods
  // **********************************************************************************************

  // Update the API address
  void updateApiAddress(String address) {
    this.apiAddress = address;
    notifyListeners();
  }

  // Update the API token
  void updateApiToken(String token) {
    this.apiToken = token;
    notifyListeners();
  }

  // **********************************************************************************************
  // Points methods
  // **********************************************************************************************

  // Remove points for the given user by addding negative Misc points
  void cashOut(int userId, int value) {
    var user = users.firstWhere((x) => x.id == userId);
    var category = categories.firstWhere((x) => x.name == 'Misc');
    user.points.add(PointsOld(
      1,
      value * -1,
      userId,
      category.id,
      category.name,
    ));

    notifyListeners();
  }

  // Add points for the given user and category
  void addPoints(int userId, int categoryId, int value) {
    var user = users.firstWhere((x) => x.id == userId);
    var category = categories.firstWhere((x) => x.id == categoryId);
    user.points.add(PointsOld(
      1,
      value,
      userId,
      categoryId,
      category.name,
    ));

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

    var newCategory = CategoryOld(categories.length + 1, name);
    categories.add(newCategory);
    notifyListeners();
    return true;
  }

  // Update the given category in the data store
  bool updateCategory(CategoryOld category) {
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