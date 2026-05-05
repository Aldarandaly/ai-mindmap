import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../ui/projects_model.dart';

class ProjectRepository {
  final ApiClient _client = ApiClient();

  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await _client.get(ApiEndpoints.projects);
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((e) => ProjectModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<ProjectModel> createProject({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.projects,
        data: {'name': name, 'description': description},
      );
      return ProjectModel.fromJson(response['data'] ?? response);
    } on ApiException {
      rethrow;
    }
  }

  Future<ProjectModel> getProject(int id) async {
    try {
      final response = await _client.get(ApiEndpoints.projectById(id));
      return ProjectModel.fromJson(response['data'] ?? response);
    } on ApiException {
      rethrow;
    }
  }
}
