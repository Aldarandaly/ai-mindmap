class DiagramModel {
  final int id;
  final int projectId;
  final String name;
  final String type;
  final String status;
  final String? diagramCode;
  final DateTime? createdAt;

  const DiagramModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    required this.status,
    this.diagramCode,
    this.createdAt,
  });

  factory DiagramModel.fromJson(Map<String, dynamic> json) {
    return DiagramModel(
      id: json['id'] as int,
      projectId: json['project_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'auto',
      status: json['status'] as String? ?? 'pending',
      diagramCode: json['diagram_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  bool get isDone => status == 'done';
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isFailed => status == 'failed';

  String get createdAtLabel {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }
}
