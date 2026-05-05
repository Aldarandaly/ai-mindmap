import '../../../core/network/api_client.dart';
import '../data/diagram_model.dart';

class DiagramRepository {
  final _client = ApiClient();

  Future<List<Diagram>> getDiagrams(int projectId) async {
    final response = await _client.get('/projects/$projectId/diagrams');
    final List data = response['data'] ?? [];
    return data.map((e) => Diagram.fromJson(e)).toList();
  }

  Future<Diagram> generateDiagram({
    required int projectId,
    required String name,
    required String description,
    required String type,
  }) async {
    final response = await _client.post(
      '/diagrams/generate',
      data: {
        'project_id': projectId,
        'name': name,
        'input_text': description,
        'type': type,
      },
    );
    return Diagram.fromJson(response['data'] ?? response);
  }

  Future<Diagram> getDiagram(int id) async {
    final response = await _client.get('/diagrams/$id');
    return Diagram.fromJson(response['data'] ?? response);
  }
}
