import 'client.dart';
import '../../model/action.dart';
import '../../model/category.dart';
import '../../model/points.dart';
import '../../model/reward.dart';
import '../../model/role.dart';
import '../../model/user.dart';
import '../../model/auth.dart';
import '../../model/health.dart';

class Api {
  final ApiClient _client;

  Api({ String? baseUrl })
   : _client = ApiClient(baseUrl: baseUrl ?? 'http://localhost:8080');
 
  // Actions
  Future<List<Action>> getActions() async {
    final response = await _client.get('/actions');
    return (response.data as List)
        .map((json) => Action.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Action> createAction({
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    final response = await _client.post('/actions', data: {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    });
    return Action.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Action> getAction(int id) async {
    final response = await _client.get('/actions/$id');
    return Action.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Action> updateAction(int id, {
    required String desc,
    required int value,
    required int categoryId,
  }) async {
    final response = await _client.put('/actions/$id', data: {
      'desc': desc,
      'value': value,
      'category_id': categoryId,
    });
    return Action.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAction(int id) async {
    await _client.delete('/actions/$id');
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final response = await _client.get('/categories');
    return (response.data as List)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory({required String name}) async {
    final response = await _client.post('/categories', data: {'name': name});
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> getCategory(int id) async {
    final response = await _client.get('/categories/$id');
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(int id, {required String name}) async {
    final response = await _client.put('/categories/$id', data: {'name': name});
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _client.delete('/categories/$id');
  }

  // Points
  Future<List<Points>> getPoints({int? userId, int? actionId}) async {
    final response = await _client.get('/points', queryParameters: {
      if (userId != null) 'user_id': userId,
      if (actionId != null) 'action_id': actionId,
    });
    return (response.data as List)
        .map((json) => Points.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Points> createPoints({
    required int value,
    required int userId,
    required int actionId,
  }) async {
    final response = await _client.post('/points', data: {
      'value': value,
      'user_id': userId,
      'action_id': actionId,
    });
    return Points.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Points> getPointsById(int id) async {
    final response = await _client.get('/points/$id');
    return Points.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Points> updatePoints(int id, {
    required int value,
    required int actionId,
  }) async {
    final response = await _client.put('/points/$id', data: {
      'value': value,
      'action_id': actionId,
    });
    return Points.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePoints(int id) async {
    await _client.delete('/points/$id');
  }

  // Rewards
  Future<List<Reward>> getRewards({int? userId}) async {
    final response = await _client.get('/rewards', queryParameters: {
      if (userId != null) 'user_id': userId,
    });
    return (response.data as List)
        .map((json) => Reward.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Reward> createReward({
    required int value,
    required int userId,
  }) async {
    final response = await _client.post('/rewards', data: {
      'value': value,
      'user_id': userId,
    });
    return Reward.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Reward> getReward(int id) async {
    final response = await _client.get('/rewards/$id');
    return Reward.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Reward> updateReward(int id, {required int value}) async {
    final response = await _client.put('/rewards/$id', data: {'value': value});
    return Reward.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteReward(int id) async {
    await _client.delete('/rewards/$id');
  }

  // Roles
  Future<List<Role>> getRoles() async {
    final response = await _client.get('/roles');
    return (response.data as List)
        .map((json) => Role.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Role> createRole({required String name}) async {
    final response = await _client.post('/roles', data: {'name': name});
    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Role> getRole(int id) async {
    final response = await _client.get('/roles/$id');
    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Role> updateRole(int id, {required String name}) async {
    final response = await _client.put('/roles/$id', data: {'name': name});
    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRole(int id) async {
    await _client.delete('/roles/$id');
  }

  // Users
  Future<List<User>> getUsers() async {
    final response = await _client.get('/users');
    return (response.data as List)
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<User> createUser({
    required String username,
    required String email,
  }) async {
    final response = await _client.post('/users', data: {
      'username': username,
      'email': email,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> getUser(int id) async {
    final response = await _client.get('/users/$id');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> updateUser(int id, {
    required String username,
    required String email,
  }) async {
    final response = await _client.put('/users/$id', data: {
      'username': username,
      'email': email,
    });
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser(int id) async {
    await _client.delete('/users/$id');
  }

  // Auth
  Future<LoginResponse> login({
    required String handle,
    required String password,
  }) async {
    final response = await _client.post('/login', data: {
      'handle': handle,
      'password': password,
    });
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // Health
  Future<HealthResponse> checkHealth() async {
    final response = await _client.get('/health');
    return HealthResponse.fromJson(response.data as Map<String, dynamic>);
  }
} 