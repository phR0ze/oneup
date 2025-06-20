import 'package:flutter/material.dart';
import 'package:oneup/model/apierr.dart';
import '../model/api_action.dart';
import '../model/category.dart';
import '../model/points.dart';
import '../model/reward.dart';
import '../model/role.dart';
import '../model/user.dart';
import '../ui/views/range.dart';
import '../utils/utils.dart';
import 'api.dart';

class AppState extends ChangeNotifier {
  final Api _api = Api(baseUrl: 'http://localhost:8080');
  Widget currentView = const RangeView(range: Range.today);

  // Set the current view
  void setCurrentView(Widget view) {
    this.currentView = view;
    notifyListeners();
  }

  // **********************************************************************************************
  // Admin methods
  // TODO: fix this
  // * Assuming any logged in user is an admin
  // * Assuming there is only one admin user
  // **********************************************************************************************

  // Get the API address
  String get apiAddress => _api.baseUrl;

  // Update the API address
  void updateApiAddress(String address) {
    notifyListeners();
  }

  // Update the API token
  void updateApiToken(String token) {
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

  // Add the new category or show a snackbar if it already exists
  // TODO: fix this
  // * Assuming any logged in user is an admin
  // * Assuming there is only one admin user
  // **********************************************************************************************
  Future<void> updateAdminPassword(BuildContext context, String password, Function()? onSuccess) async {
    if (utils.notEmpty(context, password)) {
      await _mutate<void>(context,
        () => _api.createPassword(1, password),
        onSuccess,
        'Password updated successfully!',
        'Password update failed',
      );
    }
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

  // **********************************************************************************************
  // Generic API response handling
  // **********************************************************************************************

  // Generic function to get a single resource from the API
  Future<T> _getOne<T>(BuildContext context,
    Future<ApiRes<T, ApiErr>> Function() apiCall, String resourceName) async
  {
    try {
      final res = await apiCall();
      if (!res.isError) {
        return res.data!;
      } else {
        utils.showSnackBarFailure(context, '$resourceName retrieval failed: ${res.error?.message}');
        return 0 as T;
      }
    } catch (error) {
      utils.showSnackBarFailure(context, '$resourceName retrieval failed: $error');
      return 0 as T;
    }
  }

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
  Future<void> _mutate<T>(BuildContext context, Future<ApiRes<T, ApiErr>> Function() apiCall,
    Function()? onSuccess, String successMessage, String errorPrefix,
  ) async {
    try {
      final res = await apiCall();
      if (!res.isError) {
        notifyListeners();
        onSuccess?.call();
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

  // Get the users without the given role from the API
  // TODO: fix this in the future
  Future<List<User>> getUsersWithoutAdminRole(BuildContext context) async {
    return _getAll<User>(context, () => _api.getUsersWithoutRole(1), 'Users without role');
  }

  // Get the roles for a user from the API
  Future<List<Role>> getUserRoles(BuildContext context, int userId) async {
    return _getAll<Role>(context, () => _api.getUserRoles(userId), 'User roles');
  }

  // Add the new user or show a snackbar if it already exists
  Future<void> addUser(BuildContext context, String username, String email) async {
    await _mutate<User>(context,
      () => _api.createUser(username: username, email: email),
      () => Navigator.pop(context),
      'User "$username" created successfully!',
      'User "$username" creation failed',
    );
  }

  // Update the user or show a snackbar if it already exists
  Future<void> updateUser(BuildContext context, User user) async {
    await _mutate<void>(context,
      () => _api.updateUser(user),
      () => Navigator.pop(context),
      'User "${user.username}" updated successfully!',
      'User "${user.username}" update failed',
    );
  }

  // Remove the user or show a snackbar if it fails
  Future<void> removeUser(BuildContext context, int id) async {
    await _mutate<void>(context,
      () => _api.deleteUser(id),
      null,
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
    await _mutate<Category>(context, 
      () => _api.createCategory(name),
      () => Navigator.pop(context),
      'Category "$name" created successfully!',
      'Category "$name" creation failed',
    );
  }

  // Update the category or show a snackbar if it already exists
  Future<void> updateCategory(BuildContext context, int id, String name) async {
    await _mutate<void>(context,
      () => _api.updateCategory(id, name),
      () => Navigator.pop(context),
      'Category "$name" updated successfully!',
      'Category "$name" update failed',
    );
  }

  // Remove the category or show a snackbar if it fails
  Future<void> removeCategory(BuildContext context, int id) async {
    await _mutate<void>(context,
      () => _api.deleteCategory(id),
      null,
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
    await _mutate<ApiAction>(context,
      () => _api.createAction(desc: desc, value: value, categoryId: categoryId),
      () => Navigator.pop(context),
      'Action "$desc" created successfully!',
      'Action "$desc" creation failed',
    );
  }

  // Update the action or show a snackbar if it already exists
  Future<void> updateAction(BuildContext context, int id, String desc, int value, int categoryId) async {
    await _mutate<void>(context,
      () => _api.updateAction(id, desc: desc, value: value, categoryId: categoryId),
      () => Navigator.pop(context),
      'Action "$desc" updated successfully!',
      'Action "$desc" update failed',
    );
  }

  // Remove the action or show a snackbar if it fails
  Future<void> removeAction(BuildContext context, int id) async {
    await _mutate<void>(context,
      () => _api.deleteAction(id),
      null,
      'Action deleted successfully!',
      'Action deletion failed',
    );
  }

  // **********************************************************************************************
  // Points methods
  // **********************************************************************************************

  // Get the sum of all points for a user and/or action within a date range
  Future<int> getPointsSum(BuildContext context, int userId, int? actionId,
    (DateTime, DateTime)? dateRange
  ) async {
    return _getOne<int>(context, () =>
      _api.getPointsSum(userId, actionId, dateRange), 'Sum');
  }

  // Get the sum of all rewards for a user within a date range
  Future<int> getRewardSum(BuildContext context, int userId,
    (DateTime, DateTime)? dateRange
  ) async {
    return _getOne<int>(context, () =>
      _api.getRewardSum(userId, dateRange), 'Sum');
  }

  // Get points for a user and/or action within a date range
  Future<List<Points>> getPoints(BuildContext context, int userId, int? actionId,
    (DateTime, DateTime)? dateRange
  ) async {
    return _getAll<Points>(context, () =>
      _api.getPoints(userId, actionId, dateRange), 'Points');
  }

  // Add points for the given user and action
  Future<void> addPoints(BuildContext context, int userId, int actionId, int value) async {
    await _mutate<Points>(context, 
      () => _api.createPoints(value: value, userId: userId, actionId: actionId),
      null,
      'Points added successfully!',
      'Points addition failed',
    );
  }

  // Remove points for the given user by adding negative points
  Future<void> cashOut(BuildContext context, int userId, int value) async {
    await _mutate<Reward>(context,
      () => _api.createReward(value: value, userId: userId),
      () => Navigator.pop(context),
      'Points cashed out successfully!',
      'Points cash out failed',
    );
  }

  // **********************************************************************************************
  // Role methods
  // **********************************************************************************************

  // Get the roles from the API
  Future<List<Role>> getRoles(BuildContext context) async {
    return _getAll<Role>(context, _api.getRoles, 'Role');
  }

  // Add the new role or show a snackbar if it already exists
  Future<void> addRole(BuildContext context, String name) async {
    await _mutate<Role>(context,
      () => _api.createRole(name: name),
      () => Navigator.pop(context),
      'Role "$name" created successfully!',
      'Role "$name" creation failed',
    );
  }

  // Update the role or show a snackbar if it already exists
  Future<void> updateRole(BuildContext context, int id, String name) async {
    await _mutate<void>(context,
      () => _api.updateRole(Role(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )),
      () => Navigator.pop(context),
      'Role "$name" updated successfully!',
      'Role "$name" update failed',
    );
  }

  // Remove the role or show a snackbar if it fails
  Future<void> removeRole(BuildContext context, int id) async {
    await _mutate<void>(context,
      () => _api.deleteRole(id),
      null,
      'Role deleted successfully!',
      'Role deletion failed',
    );
  }
}
