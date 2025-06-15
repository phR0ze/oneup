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

      final data = (response.data as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiRes.success(data);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }

  // Get a resource of type T by id
  Future<ApiRes<T, ApiErr>> getById<T>(String path, int id,
    T Function(Map<String, dynamic>) fromJson) async
  {
    try {
      _setAccessToken();
      final response = await _dio.get('$path/$id');
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

  // **********************************************************************************************
  // Categories
  // **********************************************************************************************

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

  // **********************************************************************************************
  // Points
  // **********************************************************************************************

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
  Future<ApiRes<void, ApiErr>> updatePoints(Points points) async {
    return await update('/points', points.id, {
      'value': points.value,
      'action_id': points.actionId,
    });
  }

  // Delete points
  Future<void> deletePoints(int id) async {
    await _dio.delete('/points/$id');
  }

  // **********************************************************************************************
  // Rewards
  // **********************************************************************************************

  // Get all rewards
  Future<ApiRes<List<Reward>, ApiErr>> getRewards({int? userId}) async {
    try {
      _setAccessToken();
      final response = await _dio.get('/rewards', queryParameters: {
        if (userId != null) 'user_id': userId,
      });
      _clearAccessToken();

      final rewards = (response.data as List)
          .map((json) => Reward.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiRes.success(rewards);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }

  // Create a reward
  Future<ApiRes<Reward, ApiErr>> createReward({
    required int value,
    required int userId,
  }) async {
    try {
      _setAccessToken();
      final response = await _dio.post('/rewards', data: {
        'value': value,
        'user_id': userId,
      });
      _clearAccessToken();
      return ApiRes.success(Reward.fromJson(response.data as Map<String, dynamic>));

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

  // Get a reward by id
  Future<ApiRes<Reward, ApiErr>> getReward(int id) async {
    try {
      _setAccessToken();
      final response = await _dio.get('/rewards/$id');
      _clearAccessToken();

      return ApiRes.success(Reward.fromJson(response.data as Map<String, dynamic>));

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
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
    try {
      _setAccessToken();
      final response = await _dio.get('/roles');
      _clearAccessToken();

      final roles = (response.data as List)
          .map((json) => Role.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiRes.success(roles);

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
  }

  // Create a role
  Future<ApiRes<Role, ApiErr>> createRole({
    required String name,
  }) async {
    try {
      _setAccessToken();
      final response = await _dio.post('/roles', data: {'name': name});
      _clearAccessToken();
      return ApiRes.success(Role.fromJson(response.data as Map<String, dynamic>));

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

  // Get a role by id
  Future<ApiRes<Role, ApiErr>> getRole(int id) async {
    try {
      _setAccessToken();
      final response = await _dio.get('/roles/$id');
      _clearAccessToken();

      return ApiRes.success(Role.fromJson(response.data as Map<String, dynamic>));

    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return ApiRes.error(ApiErr.fromJson(e.response!.data as Map<String, dynamic>));
      } else {
        rethrow;
      }
    }
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
    return getById<User>('/users', id, User.fromJson);
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