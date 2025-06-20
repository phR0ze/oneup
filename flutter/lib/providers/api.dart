import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final String? _baseUrl;
  String? _accessToken;
  int? _accessTokenExpiresAt; // Expiry time in seconds since epoch

  // Constructor
  Api({ String? baseUrl })
   : _baseUrl = baseUrl, _dio = Dio()
  {
    if (kIsWeb) {
      // For web, use relative URLs (no base URL needed)
      _dio.options.baseUrl = '';
    } else {
      // For non-web, use the provided base URL or default
      _dio.options.baseUrl = baseUrl ?? 'http://localhost:8080';
    }
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  // Get the base URL
  String get baseUrl => _baseUrl!;

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
    return getOne<Simple>('/api/health', Simple.fromJson);
  } 

  // Update the given user's password
  // TODO: would need to check if the logged in user is an admin or the user themselves
  Future<ApiRes<void, ApiErr>> createPassword(int userId, String password) async {
    return create<void>('/api/passwords', {
      'user_id': userId,
      'password': password,
    }, null);
  }

  // Login to the API and get the access token
  Future<ApiRes<void, ApiErr>> login({
    required String handle, required String password
  }) async {
    try {

      // Login to the API
      final response = await _dio.post('/api/login', data: {
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

      try {
        return ApiRes.success(fromJson(response.data as Map<String, dynamic>));
      } catch (e) {
        // If fromJson fails, try direct cast to T if response.data is already the right type
        if (response.data is T) {
          return ApiRes.success(response.data as T);
        }
        rethrow;
      }

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
    T Function(Map<String, dynamic>)? fromJson) async
  {
    try {
      _setAccessToken();
      final response = await _dio.post(path, data: data);
      _clearAccessToken();

      if (fromJson == null) {
        return ApiRes.success(null as T);
      }
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
    return getAll<ApiAction>('/api/actions', ApiAction.fromJson);
  }

  // Create an action
  Future<ApiRes<ApiAction, ApiErr>> createAction({
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    return create<ApiAction>('/api/actions', {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    }, ApiAction.fromJson);
  }

  // Get an action by id
  Future<ApiRes<ApiAction, ApiErr>> getAction(int id) async {
    return getOne<ApiAction>('/api/actions/$id', ApiAction.fromJson);
  }

  // Update an action
  Future<ApiRes<void, ApiErr>> updateAction(int id, {
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    return update('/api/actions', id, {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    });
  }

  // Delete an action
  Future<ApiRes<void, ApiErr>> deleteAction(int id) async {
    return delete('/api/actions', id);
  }

  // **********************************************************************************************
  // Categories
  // **********************************************************************************************

  // Get all categories
  Future<ApiRes<List<Category>, ApiErr>> getCategories() async {
    return getAll<Category>('/api/categories', Category.fromJson);
  }

  // Create a category
  Future<ApiRes<Category, ApiErr>> createCategory(String name) async {
    return create<Category>('/api/categories', {
      'name': name,
    }, Category.fromJson);
  }

  // Get a category by id
  Future<ApiRes<Category, ApiErr>> getCategory(int id) async {
    return getOne<Category>('/api/categories/$id', Category.fromJson);
  }

  // Update a category
  Future<ApiRes<void, ApiErr>> updateCategory(int id, String name) async {
    return update('/api/categories', id, {'name': name});
  }

  // Delete a category
  Future<ApiRes<void, ApiErr>> deleteCategory(int id) async {
    return delete('/api/categories', id);
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
  Future<ApiRes<int, ApiErr>> getPointsSum(int? userId, int? actionId,
    (DateTime, DateTime)? dateRange,
  ) async {
    var params = [];
    if (userId != null) params.add('user_id=$userId');
    if (actionId != null) params.add('action_id=$actionId');
    if (dateRange != null) {
      params.add('start_date=${dateRange.$1.toUtc().toIso8601String()}');
      params.add('end_date=${dateRange.$2.toUtc().toIso8601String()}');
    }
    var path = '/api/points/sum?' + params.join('&');
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
    var path = '/api/points?' + params.join('&');
    return getAll<Points>(path, Points.fromJson);
  }

  // Create points
  Future<ApiRes<Points, ApiErr>> createPoints({
    required int value,
    required int userId,
    required int actionId,
  }) async {
    return create<Points>('/api/points', {
      'value': value,
      'user_id': userId,
      'action_id': actionId,
    }, Points.fromJson);
  }

  // Get points by id
  Future<ApiRes<Points, ApiErr>> getPointsById(int id) async {
    return getOne<Points>('/api/points/$id', Points.fromJson);
  }

  // Update points
  Future<ApiRes<void, ApiErr>> updatePoints(Points points) async {
    return update('/api/points', points.id, {
      'value': points.value,
      'action_id': points.actionId,
    });
  }

  // Delete points
  Future<ApiRes<void, ApiErr>> deletePoints(int id) async {
    return delete('/api/points', id);
  }

  // **********************************************************************************************
  // Rewards
  // **********************************************************************************************

  // Get all rewards
  Future<ApiRes<List<Reward>, ApiErr>> getRewards(int userId) async {
    return getAll<Reward>('/api/rewards?user_id=$userId', Reward.fromJson);
  }

  /// Get sum of rewards for a user and/or action and/or date range
  /// 
  /// - Supports ISO 8601 date time range:
  ///   - Start defines the oldest date to include in the sum
  ///   - End defines the newest date to include in the sum
  /// 
  /// #### Parameters
  /// - userId: the user id
  /// - actionId: the action id
  /// - dateRange: the date range
  /// - returns the sum of rewards for the user and/or action and/or date range
  Future<ApiRes<int, ApiErr>> getRewardSum(int? userId,
    (DateTime, DateTime)? dateRange,
  ) async {
    var params = [];
    if (userId != null) params.add('user_id=$userId');
    if (dateRange != null) {
      params.add('start_date=${dateRange.$1.toUtc().toIso8601String()}');
      params.add('end_date=${dateRange.$2.toUtc().toIso8601String()}');
    }
    var path = '/api/rewards/sum?' + params.join('&');
    return getOne<int>(path, (json) => json['sum'] as int);
  }

  // Create a reward
  Future<ApiRes<Reward, ApiErr>> createReward({
    required int value,
    required int userId,
  }) async {
    return create<Reward>('/api/rewards', {
      'value': value,
      'user_id': userId,
    }, Reward.fromJson);
  }

  // Get a reward by id
  Future<ApiRes<Reward, ApiErr>> getReward(int id) async {
    return getOne<Reward>('/api/rewards/$id', Reward.fromJson);
  }

  // Update a reward
  Future<ApiRes<void, ApiErr>> updateReward(Reward reward) async {
    return update('/api/rewards', reward.id, {
      'value': reward.value,
    });
  }

  // Delete a reward
  Future<ApiRes<void, ApiErr>> deleteReward(int id) async {
    return delete('/api/rewards', id);
  }

  // **********************************************************************************************
  // Roles
  // **********************************************************************************************

  // Get all roles
  Future<ApiRes<List<Role>, ApiErr>> getRoles() async {
    return getAll<Role>('/api/roles', Role.fromJson);
  }

  // Create a role
  Future<ApiRes<Role, ApiErr>> createRole({
    required String name,
  }) async {
    return create<Role>('/api/roles', {
      'name': name,
    }, Role.fromJson);
  }

  // Get a role by id
  Future<ApiRes<Role, ApiErr>> getRole(int id) async {
    return getOne<Role>('/api/roles/$id', Role.fromJson);
  }

  // Update a role
  Future<ApiRes<void, ApiErr>> updateRole(Role role) async {
    return update('/api/roles', role.id, {
      'name': role.name,
    });
  }

  // Delete a role
  Future<ApiRes<void, ApiErr>> deleteRole(int id) async {
    return delete('/api/roles', id);
  }

  // **********************************************************************************************
  // Users
  // **********************************************************************************************

  // Get all users
  Future<ApiRes<List<User>, ApiErr>> getUsers() async {
    return getAll<User>('/api/users', User.fromJson);
  }


  // Get all users without the given role
  Future<ApiRes<List<User>, ApiErr>> getUsersWithoutRole(int roleId) async {
    return getAll<User>('/api/users?role_id_ne=$roleId', User.fromJson);
  }

  // Create a user
  Future<ApiRes<User, ApiErr>> createUser({
    required String username,
    required String email,
  }) async {
    return create<User>('/api/users', {
      'username': username,
      'email': email,
    }, User.fromJson);
  }

  // Get a user by id
  Future<ApiRes<User, ApiErr>> getUser(int id) async {
    return getOne<User>('/api/users/$id', User.fromJson);
  }

  // Get roles for a user
  Future<ApiRes<List<Role>, ApiErr>> getUserRoles(int id) async {
    return getAll<Role>('/api/users/$id/roles', Role.fromJson);
  }

  // Update a user
  Future<ApiRes<void, ApiErr>> updateUser(User user) async {
    return update('/api/users', user.id, {
      'username': user.username,
      'email': user.email,
    });
  }

  // Delete a user
  Future<ApiRes<void, ApiErr>> deleteUser(int id) async {
    return delete('/api/users', id);
  }
} 