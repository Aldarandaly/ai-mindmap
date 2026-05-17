import '../../../core/network/api_client.dart';
import '../../projects/data/projects_model.dart';

class ProjectRepository {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getProjects() async {
    try {
      final response = await _client.get('/projects');
      final List data = response is List ? response : response['data'] ?? [];
      return {
        'success': true,
        'data': data.map((e) => Project.fromJson(e)).toList(),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createProject(String name) async {
    try {
      final response = await _client.post('/projects', data: {'name': name});
      final projectData = response is Map
          ? response['data'] ?? response
          : response;
      return {'success': true, 'data': Project.fromJson(projectData)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProject(int id) async {
    try {
      final response = await _client.get('/projects/$id');
      return {
        'success': true,
        'data': Project.fromJson(response['data'] ?? response),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
