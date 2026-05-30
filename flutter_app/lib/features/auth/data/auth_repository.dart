import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final token = response['token'] as String?;
      if (token != null) await _client.saveToken(token);

      final name = response['user']?['name'] as String?;
      if (name != null) await _client.saveUserName(name);

      return {'success': true, 'data': response};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      final token = response['token'] as String?;
      if (token != null) await _client.saveToken(token);

      return {'success': true, 'data': response};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } finally {
      await _client.clearToken();
    }
  }

  Future<bool> isLoggedIn() => _client.hasToken();

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _client.post(
        '/forgot-password',
        data: {'email': email},
      );
      return {
        'success': true,
        'message': response['message'] ?? 'Reset link sent!',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
  required String token,
  required String email,
  required String password,
  required String passwordConfirmation,
}) async {
  try {
    final response = await _client.post(
      '/reset-password',
      data: {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return {
      'success': true,
      'message': response['message'] ?? 'Password reset successful',
    };
  } catch (e) {
    return {
      'success': false,
      'message': e.toString(),
    };
  }
}
}
