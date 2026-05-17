import '../../../core/network/api_client.dart';
import '../data/diagram_model.dart';

class DiagramRepository {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getDiagrams(int projectId) async {
    try {
      final response = await _client.get('/projects/$projectId/diagrams');

      List data = [];
      if (response is List) {
        data = response;
      } else if (response is Map) {
        final d = response['data'];
        if (d is List) {
          data = d;
        } else if (d is Map) {
          data = [d];
        }
      }

      return {
        'success': true,
        'data': data
            .map((e) => Diagram.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRecentDiagrams() async {
    try {
      final response = await _client.get('/diagrams/recent');
      print('RECENT RESPONSE: $response');
      List data = response is List ? response : response['data'] ?? [];
      return {
        'success': true,
        'data': data
            .map((e) => Diagram.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      };
    } catch (e) {
      print('RECENT ERROR: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Diagram> generateDiagram({
  required int projectId,
  required String name,
  required String description,
  required String type,
}) async {
  try {
    final response = await _client.post(
      '/diagrams/generate',
      data: {
        'project_id': projectId,
        'name': name,
        'input_text': description,
        'type': type,
      },
    );
    print('GENERATE RESPONSE: $response');

    if (response is Map && response['error'] != null) {
      throw Exception(response['error']['message'] ?? 'Generation failed');
    }

    final data = response is Map ? (response['data'] ?? response) : response;
    return Diagram.fromJson(Map<String, dynamic>.from(data));
  } catch (e) {
    print('GENERATE ERROR: $e');
    rethrow;
  }
}

  Future<Diagram> getDiagram(int id) async {
    final response = await _client.get('/diagrams/$id');
    print('GET DIAGRAM RESPONSE: $response');
    final data = response is Map ? (response['data'] ?? response) : response;
    return Diagram.fromJson(Map<String, dynamic>.from(data));
  }
}
