import 'package:dio/dio.dart';
import '../model/action.dart';
import '../model/category.dart';
import '../model/points.dart';
import '../model/reward.dart';
import '../model/role.dart';
import '../model/user.dart';
import '../model/auth.dart';
import '../model/simple.dart';
import '../model/apierr.dart';

class ApiRes<T, E> {
  final T? data;
  final E? error;
  final bool isError;

  ApiRes.success(this.data) : error = null, isError = false;
  ApiRes.error(this.error) : data = null, isError = true;
}

class Api {
  final Dio _dio;
  final _baseUrl;
  String? _accessToken;

  // Constructor
  Api({ String? baseUrl })
   : _baseUrl = baseUrl ?? 'http://localhost:8080', _dio = Dio()
  {
    _dio.options.baseUrl = this._baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  // Set the access token for the current dio instance
  void _setAccessToken() {
    _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
  }

  // Clear the access token for the current dio instance
  void _clearAccessToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Check if the user is authorized
  bool isAdminAuthorized() {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  // Deauthorize the user
  void deauthorize() {
    _accessToken = null;
    _clearAccessToken();
  }

  // Check the API's health
  Future<Simple> checkHealth() async {
    final response = await _dio.get('/health');
    return Simple.fromJson(response.data as Map<String, dynamic>);
  } 

  // Login to the API and get the access token
  Future<LoginResponse> login({
    required String handle, required String password
  }) async {
    final response = await _dio.post('/login', data: {
      'handle': handle,
      'password': password,
    });
    var login = LoginResponse.fromJson(response.data as Map<String, dynamic>);
    _accessToken = login.accessToken;
    return login;
  }

  // Get all actions
  Future<List<Action>> getActions() async {
    _setAccessToken();
    final response = await _dio.get('/actions');
    _clearAccessToken();

    return (response.data as List)
        .map((json) => Action.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Create an action
  Future<Action> createAction({
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    _setAccessToken();
    final response = await _dio.post('/actions', data: {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    });
    _clearAccessToken();

    return Action.fromJson(response.data as Map<String, dynamic>);
  }

  // Get an action by id
  Future<Action> getAction(int id) async {
    _setAccessToken();
    final response = await _dio.get('/actions/$id');
    _clearAccessToken();

    return Action.fromJson(response.data as Map<String, dynamic>);
  }

  // Update an action
  Future<Action> updateAction(int id, {
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    _setAccessToken();
    final response = await _dio.put('/actions/$id', data: {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    });
    _clearAccessToken();

    return Action.fromJson(response.data as Map<String, dynamic>);
  }

  // Delete an action
  Future<void> deleteAction(int id) async {
    _setAccessToken();
    await _dio.delete('/actions/$id');
    _clearAccessToken();
  }

  // Get all categories
  Future<List<Category>> getCategories() async {
    _setAccessToken();
    final response = await _dio.get('/categories');
    _clearAccessToken();

    return (response.data as List)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Create a category
  Future<Category> createCategory({required String name}) async {
    _setAccessToken();
    final response = await _dio.post('/categories', data: {'name': name});
    _clearAccessToken();

    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  // Get a category by id
  Future<Category> getCategory(int id) async {
    _setAccessToken();
    final response = await _dio.get('/categories/$id');
    _clearAccessToken();

    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  // Update a category
  Future<Category> updateCategory(int id, {required String name}) async {
    _setAccessToken();
    final response = await _dio.put('/categories/$id', data: {'name': name});
    _clearAccessToken();

    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  // Delete a category
  Future<void> deleteCategory(int id) async {
    _setAccessToken();
    await _dio.delete('/categories/$id');
    _clearAccessToken();
  }

  // Get all points
  Future<List<Points>> getPoints({int? userId, int? actionId}) async {
    final response = await _dio.get('/points', queryParameters: {
      if (userId != null) 'user_id': userId,
      if (actionId != null) 'action_id': actionId,
    });

    return (response.data as List)
        .map((json) => Points.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Create points
  Future<Points> createPoints({
    required int value,
    required int userId,
    required int actionId,
  }) async {
    final response = await _dio.post('/points', data: {
      'value': value,
      'user_id': userId,
      'action_id': actionId,
    });

    return Points.fromJson(response.data as Map<String, dynamic>);
  }

  // Get points by id
  Future<Points> getPointsById(int id) async {
    final response = await _dio.get('/points/$id');

    return Points.fromJson(response.data as Map<String, dynamic>);
  }

  // Update points
  Future<Points> updatePoints(int id, {
    required int value,
    required int actionId,
  }) async {
    final response = await _dio.put('/points/$id', data: {
      'value': value,
      'action_id': actionId,
    });

    return Points.fromJson(response.data as Map<String, dynamic>);
  }

  // Delete points
  Future<void> deletePoints(int id) async {
    await _dio.delete('/points/$id');
  }

  // Get all rewards
  Future<List<Reward>> getRewards({int? userId}) async {
    final response = await _dio.get('/rewards', queryParameters: {
      if (userId != null) 'user_id': userId,
    });

    return (response.data as List)
        .map((json) => Reward.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Create a reward
  Future<Reward> createReward({
    required int value,
    required int userId,
  }) async {
    final response = await _dio.post('/rewards', data: {
      'value': value,
      'user_id': userId,
    });

    return Reward.fromJson(response.data as Map<String, dynamic>);
  }

  // Get a reward by id
  Future<Reward> getReward(int id) async {
    final response = await _dio.get('/rewards/$id');

    return Reward.fromJson(response.data as Map<String, dynamic>);
  }

  // Update a reward
  Future<Reward> updateReward(int id, {required int value}) async {
    final response = await _dio.put('/rewards/$id', data: {'value': value});

    return Reward.fromJson(response.data as Map<String, dynamic>);
  }

  // Delete a reward
  Future<void> deleteReward(int id) async {
    await _dio.delete('/rewards/$id');
  }

  // Get all roles
  Future<List<Role>> getRoles() async {
    _setAccessToken();
    final response = await _dio.get('/roles');
    _clearAccessToken();

    return (response.data as List)
        .map((json) => Role.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Create a role
  Future<Role> createRole({required String name}) async {
    _setAccessToken();
    final response = await _dio.post('/roles', data: {'name': name});
    _clearAccessToken();

    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  // Get a role by id
  Future<Role> getRole(int id) async {
    _setAccessToken();
    final response = await _dio.get('/roles/$id');
    _clearAccessToken();

    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  // Update a role
  Future<Role> updateRole(int id, {required String name}) async {
    _setAccessToken();
    final response = await _dio.put('/roles/$id', data: {'name': name});
    _clearAccessToken();

    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  // Delete a role
  Future<void> deleteRole(int id) async {
    _setAccessToken();
    await _dio.delete('/roles/$id');
    _clearAccessToken();
  }

  // Get all users
  Future<ApiRes<List<User>, ApiErr>> getUsers() async {
    try {
      _setAccessToken();
      final response = await _dio.get('/users');
      _clearAccessToken();

      final users = (response.data as List)
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiRes.success(users);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }

  // Create a user
  Future<ApiRes<User, ApiErr>> createUser({
    required String username,
    required String email,
  }) async {
    try {
      _setAccessToken();
      final response = await _dio.post('/users', data: {
        'username': username,
        'email': email,
      });
      _clearAccessToken();
      return ApiRes.success(User.fromJson(response.data as Map<String, dynamic>));

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        // Ensure the API errors are surfaced to the caller
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        // Only rethrow if the error is not a known ApiErr
        rethrow;
      }
    }
  }

  // Get a user by id
  Future<User> getUser(int id) async {
    _setAccessToken();
    final response = await _dio.get('/users/$id');
    _clearAccessToken();

    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // Update a user
  Future<ApiRes<void, ApiErr>> updateUser(User user) async {
    _setAccessToken();
    try {
      await _dio.put('/users/${user.id}', data: {
        'username': user.username,
        'email': user.email,
      });
      _clearAccessToken();
      return ApiRes.success(null);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        // Ensure the API errors are surfaced to the caller
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        // Only rethrow if the error is not a known ApiErr
        rethrow;
      }
    }
  }

  // Delete a user
  Future<ApiRes<void, ApiErr>> deleteUser(int id) async {
    _setAccessToken();
    try {
      await _dio.delete('/users/$id');
      _clearAccessToken();
      return ApiRes.success(null);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }
} 