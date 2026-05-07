import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _loadTokenOnInit();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );

  // ── Token Auto Load ───────────────────────────────────────

  Future<void> _loadTokenOnInit() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // ── Token Management ──────────────────────────────────────

  Future<void> saveUserName(String name) async {
    await _storage.write(key: 'user_name', value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> loadToken() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ── HTTP Methods ──────────────────────────────────────────

  Future<dynamic> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  // ── Error Handler ─────────────────────────────────────────

  ApiException _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return const UnauthorizedException();
      case 404:
        return NotFoundException(
          message: e.response?.data?['message'] ?? 'Not found.',
        );
      case 422:
        final errors = e.response?.data?['errors'] as Map<String, dynamic>?;
        final first = errors?.values.first;
        final msg = first is List
            ? first.first.toString()
            : e.response?.data?['message']?.toString() ?? 'Validation error.';
        return ApiException(message: msg, statusCode: 422);
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          return const NetworkException();
        }
        return ApiException(
          message:
              e.response?.data?['message']?.toString() ??
              'Something went wrong.',
          statusCode: e.response?.statusCode,
        );
    }
  }
}
