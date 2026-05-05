import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'diagram_model.dart';

class DiagramRepository {
  final ApiClient _client = ApiClient();

  Future<List<DiagramModel>> getProjectDiagrams(int projectId) async {
    try {
      final response = await _client.get(ApiEndpoints.projectDiagrams(projectId));
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((e) => DiagramModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    }
  }

  Future<DiagramModel> generateDiagram({
    required int projectId,
    required String name,
    required String description, // ✅ كان text، اتغير لـ description
    required String type,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.generateDiagram,
        data: {
          'project_id': projectId,
          'name': name,
          'text': description, // بنبعته للـ API كـ text زي ما هو متوقع
          'type': type,
          'mode': 'generate',
        },
      );
      return DiagramModel.fromJson(response['data'] ?? response);
    } on ApiException {
      rethrow;
    }
  }

  Future<DiagramModel> getDiagram(int id) async {
    try {
      final response = await _client.get(ApiEndpoints.diagramById(id));
      return DiagramModel.fromJson(response['data'] ?? response);
    } on ApiException {
      rethrow;
    }
  }
}