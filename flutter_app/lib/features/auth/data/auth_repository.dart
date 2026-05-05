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

      // Save token automatically
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
}
