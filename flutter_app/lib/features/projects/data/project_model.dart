class Project {
  final int id;
  final String name;
  final int userId;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}