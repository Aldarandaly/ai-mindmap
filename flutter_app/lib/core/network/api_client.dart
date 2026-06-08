import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );
    _loadTokenOnInit();
  }

  Future<void> _loadTokenOnInit() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

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

  Future<dynamic> sendMessage({
    required int projectId,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/send',
        data: {'project_id': projectId, 'message': message},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return const UnauthorizedException();

      case 404:
        return NotFoundException(
          message: e.response?.data is Map
              ? (e.response?.data['message']?.toString() ?? 'Not found.')
              : 'Not found.',
        );

      case 422:
        try {
          final data = e.response?.data;
          String msg = 'Validation error.';
          if (data is Map) {
            final errors = data['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final first = errors.values.first;
              if (first is List && first.isNotEmpty) {
                msg = first[0].toString();
              } else if (first is String) {
                msg = first;
              }
            } else if (data['message'] is String) {
              msg = data['message'];
            }
          } else if (data is String) {
            msg = data;
          }
          return ApiException(message: msg, statusCode: 422);
        } catch (ex) {
          return const ApiException(
            message: 'Validation error.',
            statusCode: 422,
          );
        }

      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          return const NetworkException();
        }

        String defaultMsg = 'Something went wrong.';
        try {
          final data = e.response?.data;
          if (data is Map) {
            defaultMsg = data['message']?.toString() ?? defaultMsg;
          } else if (data is String) {
            defaultMsg = data;
          }
        } catch (_) {}

        return ApiException(
          message: defaultMsg,
          statusCode: e.response?.statusCode,
        );
    }
  }
}
