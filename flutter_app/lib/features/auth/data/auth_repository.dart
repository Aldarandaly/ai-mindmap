import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? e.response?.data['message'] ?? 'Something went wrong'
            : e.response?.data.toString() ?? 'Something went wrong',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? e.response?.data['message'] ?? 'Something went wrong'
            : e.response?.data.toString() ?? 'Something went wrong',
      };
    }
  }
}
