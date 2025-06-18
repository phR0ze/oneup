import 'package:flutter/material.dart';
import 'package:oneup/model/apierr.dart';
import '../model/api_action.dart';
import '../model/category.dart';
import '../model/user.dart';
import '../ui/views/range.dart';
import '../utils/utils.dart';
import '../model/user_old.dart';
import '../model/points_old.dart';
import '../model/category_old.dart';
import 'api.dart';

class AppState extends ChangeNotifier {
  final Api _api = Api();

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

  // Get the API address
  String get apiAddress => _api.baseUrl;

  // Update the API address
  void updateApiAddress(String address) {
    //_api.baseUrl = address;
    notifyListeners();
  }

  // Update the API token
  void updateApiToken(String token) {
    // this.apiToken = token;
    notifyListeners();
  }

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
  Future<void> login(BuildContext context, String? handle, String password) async {
    try {
      final res = await _api.login(handle: handle ?? "admin", password: password);
      if (!res.isError) {
        notifyListeners();
        Navigator.pop(context);
        utils.showSnackBarSuccess(context, 'Login successful!');
      } else {
        utils.showSnackBarFailure(context, 'Login failed: ${res.error?.message}');
      }
    } catch (error) {
      utils.showSnackBarFailure(context, 'Login failed: $error');
    }
  }

  // Update the admin password
  void updateAdminPassword(String password) {
    // this.adminPass = password;
    notifyListeners();
  }

  // **********************************************************************************************
  // Generic API response handling
  // **********************************************************************************************

  // Generic function to get resources from the API
  Future<List<T>> _getAll<T>(BuildContext context,
    Future<ApiRes<List<T>, ApiErr>> Function() apiCall, String resourceName) async
  {
    try {
      final res = await apiCall();
      if (!res.isError) {
        return res.data!;
      } else {
        utils.showSnackBarFailure(context, '$resourceName retrieval failed: ${res.error?.message}');
        return [];
      }
    } catch (error) {
      utils.showSnackBarFailure(context, '$resourceName retrieval failed: $error');
      return [];
    }
  }

  // Handle API responses without any return value
  Future<void> _mutate<T>(BuildContext context, bool popDialog,
    Future<ApiRes<T, ApiErr>> Function() apiCall, String successMessage, String errorPrefix,
  ) async {
    try {
      final res = await apiCall();
      if (!res.isError) {
        notifyListeners();
        if (popDialog) {
          Navigator.pop(context);
        }
        utils.showSnackBarSuccess(context, successMessage);
      } else {
        utils.showSnackBarFailure(context, '$errorPrefix: ${res.error?.message}');
      }
    } catch (error) {
      utils.showSnackBarFailure(context, '$errorPrefix: $error');
    }
  }

  // **********************************************************************************************
  // User methods
  // **********************************************************************************************

  // Get the users from the API
  Future<List<User>> getUsers(BuildContext context) async {
    return _getAll<User>(context, _api.getUsers, 'User');
  }

  // Add the new user or show a snackbar if it already exists
  Future<void> addUser(BuildContext context, String username, String email) async {
    await _mutate<User>(context, true, () =>
      _api.createUser(username: username, email: email),
      'User "$username" created successfully!',
      'User "$username" creation failed',
    );
  }

  // Update the user or show a snackbar if it already exists
  Future<void> updateUser(BuildContext context, User user) async {
    await _mutate<void>(context, true, () =>
      _api.updateUser(user),
      'User "${user.username}" updated successfully!',
      'User "${user.username}" update failed',
    );
  }

  // Remove the user or show a snackbar if it fails
  Future<void> removeUser(BuildContext context, int id) async {
    await _mutate<void>(context, false, () =>
      _api.deleteUser(id),
      'User deleted successfully!',
      'User deletion failed',
    );
  }

  // **********************************************************************************************
  // Category methods
  // **********************************************************************************************

  // Get the categories from the API
  Future<List<Category>> getCategories(BuildContext context) async {
    return _getAll<Category>(context, _api.getCategories, 'Category');
  }

  // Add the new category or show a snackbar if it already exists
  Future<void> addCategory(BuildContext context, String name) async {
    await _mutate<Category>(context, true, () =>
      _api.createCategory(name),
      'Category "$name" created successfully!',
      'Category "$name" creation failed',
    );
  }

  // Update the category or show a snackbar if it already exists
  Future<void> updateCategory(BuildContext context, int id, String name) async {
    await _mutate<void>(context, true, () =>
      _api.updateCategory(id, name),
      'Category "$name" updated successfully!',
      'Category "$name" update failed',
    );
  }

  // Remove the category or show a snackbar if it fails
  Future<void> removeCategory(BuildContext context, int id) async {
    await _mutate<void>(context, false, () =>
      _api.deleteCategory(id),
      'Category deleted successfully!',
      'Category deletion failed',
    );
  }

  // **********************************************************************************************
  // Action methods
  // **********************************************************************************************

  // Get the actions from the API
  Future<List<ApiAction>> getActions(BuildContext context) async {
    return _getAll<ApiAction>(context, _api.getActions, 'Action');
  }

  // Add the new action or show a snackbar if it already exists
  Future<void> addAction(BuildContext context, String desc, int value, int categoryId) async {
    await _mutate<ApiAction>(context, true, () =>
      _api.createAction(desc: desc, value: value, categoryId: categoryId),
      'Action "$desc" created successfully!',
      'Action "$desc" creation failed',
    );
  }

  // Update the action or show a snackbar if it already exists
  Future<void> updateAction(BuildContext context, int id, String desc, int value, int categoryId) async {
    await _mutate<void>(context, true, () =>
      _api.updateAction(id, desc: desc, value: value, categoryId: categoryId),
      'Action "$desc" updated successfully!',
      'Action "$desc" update failed',
    );
  }

  // Remove the action or show a snackbar if it fails
  Future<void> removeAction(BuildContext context, int id) async {
    await _mutate<void>(context, false, () =>
      _api.deleteAction(id),
      'Action deleted successfully!',
      'Action deletion failed',
    );
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

}