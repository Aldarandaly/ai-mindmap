class Diagram {
  final int id;
  final int projectId;
  final String name;
  final String inputText;
  final String? diagramCode;
  final String type;
  final String status;
  final DateTime createdAt;

  Diagram({
    required this.id,
    required this.projectId,
    required this.name,
    required this.inputText,
    this.diagramCode,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';

  String get createdAtLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  factory Diagram.fromJson(Map<String, dynamic> json) {
    return Diagram(
      id: json['id'],
      projectId: json['project_id'],
      name: json['name'] ?? '',
      inputText: json['input_text'],
      diagramCode: json['diagram_code'],
      type: json['type'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
