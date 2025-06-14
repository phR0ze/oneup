import 'package:dio/dio.dart';

class Client {
  final Dio _dio;
  final String baseUrl;
  
  Client({ String? baseUrl, Dio? dio })
   : baseUrl = baseUrl ?? 'http://localhost:8080', _dio = dio ?? Dio()
  {
    _dio.options.baseUrl = this.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Response<T>> get<T>(String path, {
    Map<String, dynamic>? queryParameters, Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(String path, {
    dynamic data, Map<String, dynamic>? queryParameters, Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(String path, {
    dynamic data, Map<String, dynamic>? queryParameters, Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(String path, {
    dynamic data, Map<String, dynamic>? queryParameters, Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
} 