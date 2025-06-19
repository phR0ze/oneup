import 'package:dio/dio.dart';
import 'dart:convert';
import '../model/api_action.dart';
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
  int? _accessTokenExpiresAt; // Expiry time in seconds since epoch

  // Constructor
  Api({ String? baseUrl })
   : _baseUrl = baseUrl ?? 'http://localhost:8080', _dio = Dio()
  {
    _dio.options.baseUrl = this._baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  // Get the base URL
  String get baseUrl => _baseUrl;

  // Set the access token for the current dio instance
  void _setAccessToken() {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    }
  }

  // Clear the access token for the current dio instance
  void _clearAccessToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Check if the user is authorized
  bool isAdminAuthorized() {
    if (_accessToken == null || _accessToken!.isEmpty) {
      return false;
    }
    return _accessTokenExpiresAt != null && _accessTokenExpiresAt! >
      DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  // Deauthorize the user
  void deauthorize() {
    _accessToken = null;
    _clearAccessToken();
  }

  // Check the API's health
  Future<ApiRes<Simple, ApiErr>> checkHealth() async {
    return getOne<Simple>('/health', Simple.fromJson);
  } 

  // Login to the API and get the access token
  Future<ApiRes<void, ApiErr>> login({
    required String handle, required String password
  }) async {
    try {

      // Login to the API
      final response = await _dio.post('/login', data: {
        'handle': handle,
        'password': password,
      });

      // Parse the response
      var login = LoginResponse.fromJson(response.data as Map<String, dynamic>);

      // Set the access token and expiration
      try {
        final parts = login.accessToken.split('.');
        if (parts.length != 3) {
          return ApiRes.error(ApiErr(message: 'Invalid token format length'));
        }
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final data = json.decode(decoded) as Map<String, dynamic>;

        // Set the access token and expiration
        _accessTokenExpiresAt = data['exp'] as int;
        _accessToken = login.accessToken;
      } catch (e) {
        return ApiRes.error(ApiErr(message: 'Invalid token format: $e'));
      }
      return ApiRes.success(null);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }

  // **********************************************************************************************
  // Generic methods
  // **********************************************************************************************

  // Get all resources of type T
  Future<ApiRes<List<T>, ApiErr>> getAll<T>(String path,
    T Function(Map<String, dynamic>) fromJson) async
  {
    try {
      _setAccessToken();
      final response = await _dio.get(path);
      _clearAccessToken();

      // Handle null or empty response
      if (response.data == null) {
        return ApiRes.success(<T>[]);
      }

      final data = response.data as List;
      final result = <T>[];
      
      // Also explicitly check for null items in response list
      for (var item in data) {
        try {
          if (item != null && item is Map<String, dynamic>) {
            result.add(fromJson(item));
          }
        } catch (e) {
          // Skip malformed items instead of failing the entire request
          print('Warning: Skipping malformed item in $path: $e');
        }
      }
      return ApiRes.success(result);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }

  // Get a resource of type T by id
  Future<ApiRes<T, ApiErr>> getOne<T>(String path,
    T Function(Map<String, dynamic>) fromJson) async
  {
    try {
      _setAccessToken();
      final response = await _dio.get(path);
      _clearAccessToken();

      return ApiRes.success(fromJson(response.data as Map<String, dynamic>));

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }

  // Create a user
  Future<ApiRes<T, ApiErr>> create<T>(String path, Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson) async
  {
    try {
      _setAccessToken();
      final response = await _dio.post(path, data: data);
      _clearAccessToken();
      return ApiRes.success(fromJson(response.data as Map<String, dynamic>));

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

  // Generic update method
  Future<ApiRes<void, ApiErr>> update(String path, int id, Map<String, dynamic> data) async {
    try {
      _setAccessToken();
      await _dio.put('$path/$id', data: data);
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

  // Delete a generic resource
  Future<ApiRes<void, ApiErr>> delete(String path, int id) async {
    try {
      _setAccessToken();
      await _dio.delete('$path/$id');
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

  // **********************************************************************************************
  // Actions
  // **********************************************************************************************

  // Get all actions
  Future<ApiRes<List<ApiAction>, ApiErr>> getActions() async {
    return getAll<ApiAction>('/actions', ApiAction.fromJson);
  }

  // Create an action
  Future<ApiRes<ApiAction, ApiErr>> createAction({
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    return create<ApiAction>('/actions', {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    }, ApiAction.fromJson);
  }

  // Get an action by id
  Future<ApiRes<ApiAction, ApiErr>> getAction(int id) async {
    return getOne<ApiAction>('/actions/$id', ApiAction.fromJson);
  }

  // Update an action
  Future<ApiRes<void, ApiErr>> updateAction(int id, {
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    return update('/actions', id, {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    });
  }

  // Delete an action
  Future<ApiRes<void, ApiErr>> deleteAction(int id) async {
    return delete('/actions', id);
  }

  // **********************************************************************************************
  // Categories
  // **********************************************************************************************

  // Get all categories
  Future<ApiRes<List<Category>, ApiErr>> getCategories() async {
    return getAll<Category>('/categories', Category.fromJson);
  }

  // Create a category
  Future<ApiRes<Category, ApiErr>> createCategory(String name) async {
    return create<Category>('/categories', {
      'name': name,
    }, Category.fromJson);
  }

  // Get a category by id
  Future<ApiRes<Category, ApiErr>> getCategory(int id) async {
    return getOne<Category>('/categories/$id', Category.fromJson);
  }

  // Update a category
  Future<ApiRes<void, ApiErr>> updateCategory(int id, String name) async {
    return update('/categories', id, {'name': name});
  }

  // Delete a category
  Future<ApiRes<void, ApiErr>> deleteCategory(int id) async {
    return delete('/categories', id);
  }

  // **********************************************************************************************
  // Points
  // **********************************************************************************************

  /// Get sum of points for a user and/or action and/or date range
  /// 
  /// - Supports ISO 8601 date time range:
  ///   - Start defines the oldest date to include in the sum
  ///   - End defines the newest date to include in the sum
  /// 
  /// #### Parameters
  /// - userId: the user id
  /// - actionId: the action id
  /// - dateRange: the date range
  /// - returns the sum of points for the user and/or action and/or date range
  Future<ApiRes<int, ApiErr>> getSum(int? userId, int? actionId,
    (DateTime, DateTime)? dateRange,
  ) async {
    var params = [];
    if (userId != null) params.add('user_id=$userId');
    if (actionId != null) params.add('action_id=$actionId');
    if (dateRange != null) {
      params.add('start_date=${dateRange.$1.toUtc().toIso8601String()}');
      params.add('end_date=${dateRange.$2.toUtc().toIso8601String()}');
    }
    var path = '/points/sum?' + params.join('&');
    return getOne<int>(path, (json) => json['sum'] as int);
  }

  // Get all points for a user and/or action and/or date range
  Future<ApiRes<List<Points>, ApiErr>> getPoints(int? userId, int? actionId,
    (DateTime, DateTime)? dateRange,
  ) async {
    var params = [];
    if (userId != null) params.add('user_id=$userId');
    if (actionId != null) params.add('action_id=$actionId');
    if (dateRange != null) {
      params.add('start_date=${dateRange.$1.toUtc().toIso8601String()}');
      params.add('end_date=${dateRange.$2.toUtc().toIso8601String()}');
    }
    var path = '/points?' + params.join('&');
    return getAll<Points>(path, Points.fromJson);
  }

  // Create points
  Future<ApiRes<Points, ApiErr>> createPoints({
    required int value,
    required int userId,
    required int actionId,
  }) async {
    return create<Points>('/points', {
      'value': value,
      'user_id': userId,
      'action_id': actionId,
    }, Points.fromJson);
  }

  // Get points by id
  Future<ApiRes<Points, ApiErr>> getPointsById(int id) async {
    return getOne<Points>('/points/$id', Points.fromJson);
  }

  // Update points
  Future<ApiRes<void, ApiErr>> updatePoints(Points points) async {
    return update('/points', points.id, {
      'value': points.value,
      'action_id': points.actionId,
    });
  }

  // Delete points
  Future<ApiRes<void, ApiErr>> deletePoints(int id) async {
    return delete('/points', id);
  }

  // **********************************************************************************************
  // Rewards
  // **********************************************************************************************

  // Get all rewards
  Future<ApiRes<List<Reward>, ApiErr>> getRewards(int userId) async {
    return getAll<Reward>('/rewards?user_id=$userId', Reward.fromJson);
  }

  // Create a reward
  Future<ApiRes<Reward, ApiErr>> createReward({
    required int value,
    required int userId,
  }) async {
    return create<Reward>('/rewards', {
      'value': value,
      'user_id': userId,
    }, Reward.fromJson);
  }

  // Get a reward by id
  Future<ApiRes<Reward, ApiErr>> getReward(int id) async {
    return getOne<Reward>('/rewards/$id', Reward.fromJson);
  }

  // Update a reward
  Future<ApiRes<void, ApiErr>> updateReward(Reward reward) async {
    return update('/rewards', reward.id, {
      'value': reward.value,
    });
  }

  // Delete a reward
  Future<ApiRes<void, ApiErr>> deleteReward(int id) async {
    return delete('/rewards', id);
  }

  // **********************************************************************************************
  // Roles
  // **********************************************************************************************

  // Get all roles
  Future<ApiRes<List<Role>, ApiErr>> getRoles() async {
    return getAll<Role>('/roles', Role.fromJson);
  }

  // Create a role
  Future<ApiRes<Role, ApiErr>> createRole({
    required String name,
  }) async {
    return create<Role>('/roles', {
      'name': name,
    }, Role.fromJson);
  }

  // Get a role by id
  Future<ApiRes<Role, ApiErr>> getRole(int id) async {
    return getOne<Role>('/roles/$id', Role.fromJson);
  }

  // Update a role
  Future<ApiRes<void, ApiErr>> updateRole(Role role) async {
    return update('/roles', role.id, {
      'name': role.name,
    });
  }

  // Delete a role
  Future<ApiRes<void, ApiErr>> deleteRole(int id) async {
    return delete('/roles', id);
  }

  // **********************************************************************************************
  // Users
  // **********************************************************************************************

  // Get all users
  Future<ApiRes<List<User>, ApiErr>> getUsers() async {
    return getAll<User>('/users', User.fromJson);
  }

  // Create a user
  Future<ApiRes<User, ApiErr>> createUser({
    required String username,
    required String email,
  }) async {
    return create<User>('/users', {
      'username': username,
      'email': email,
    }, User.fromJson);
  }

  // Get a user by id
  Future<ApiRes<User, ApiErr>> getUser(int id) async {
    return getOne<User>('/users/$id', User.fromJson);
  }

  // Get roles for a user
  Future<ApiRes<List<Role>, ApiErr>> getUserRoles(int id) async {
    return getAll<Role>('/users/$id/roles', Role.fromJson);
  }

  // Update a user
  Future<ApiRes<void, ApiErr>> updateUser(User user) async {
    return update('/users', user.id, {
      'username': user.username,
      'email': user.email,
    });
  }

  // Delete a user
  Future<ApiRes<void, ApiErr>> deleteUser(int id) async {
    return delete('/users', id);
  }
} 