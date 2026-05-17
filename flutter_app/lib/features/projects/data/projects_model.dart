class Project {
  final int id;
  final String name;
  final String? description;
  final int diagramsCount;
  final String createdAt;
  final String updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.diagramsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // updatedAtLabel getter
  String get updatedAtLabel {
    try {
      final dt = DateTime.parse(updatedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return updatedAt;
    }
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id:            json['id'] as int,
      name:          json['name'] as String,
      description:   json['description'] as String?,
      diagramsCount: json['diagrams_count'] as int? ?? 0,
      createdAt:     json['created_at'] as String,
      updatedAt:     json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'name':           name,
    'description':    description,
    'diagrams_count': diagramsCount,
    'created_at':     createdAt,
    'updated_at':     updatedAt,
  };
}