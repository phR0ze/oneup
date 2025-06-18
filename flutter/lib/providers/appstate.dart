import 'package:flutter/material.dart';
import 'package:oneup/model/apierr.dart';
import '../model/api_action.dart';
import '../model/category.dart';
import '../model/points.dart';
import '../model/user.dart';
import '../ui/views/range.dart';
import '../utils/utils.dart';
import 'api.dart';

class AppState extends ChangeNotifier {
  final Api _api = Api();
  Widget currentView = const RangeView(range: Range.today);


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

  // Get points for a user and/or action
  Future<List<Points>> getPoints(BuildContext context, int userId, int? actionId) async {
    return _getAll<Points>(context, () =>
      _api.getPoints(userId: userId, actionId: actionId), 'Points');
  }

  // Add points for the given user and action
  Future<void> addPoints(BuildContext context, int userId, int actionId, int value) async {
    await _mutate<Points>(context, true, () =>
      _api.createPoints(value: value, userId: userId, actionId: actionId),
      'Points added successfully!',
      'Points addition failed',
    );
  }

  // Remove points for the given user by adding negative points
  Future<void> cashOut(BuildContext context, int userId, int value) async {
    var actions = await getActions(context);
    var defaultAction = actions.firstWhere((x) => x.desc == 'Default');
    
    await _mutate<Points>(context, true, () =>
      _api.createPoints(value: -value, userId: userId, actionId: defaultAction.id),
      'Points cashed out successfully!',
      'Points cash out failed',
    );
  }

}