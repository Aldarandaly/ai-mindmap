class ProjectModel {
  final int id;
  final String name;
  final String description;
  final int diagramsCount;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.diagramsCount,
    this.updatedAt,
    this.createdAt,
  });

  // ─── From Laravel API response ───────────────────────────
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      diagramsCount: json['diagrams_count'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'diagrams_count': diagramsCount,
        'updated_at': updatedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  // ─── Helpers ─────────────────────────────────────────────

  /// e.g. "Updated 2h ago" / "Updated yesterday"
  String get updatedAtLabel {
    if (updatedAt == null) return '';
    final diff = DateTime.now().difference(updatedAt!);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Updated yesterday';
    return 'Updated ${diff.inDays}d ago';
  }

  ProjectModel copyWith({
    int? id,
    String? name,
    String? description,
    int? diagramsCount,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      diagramsCount: diagramsCount ?? this.diagramsCount,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
