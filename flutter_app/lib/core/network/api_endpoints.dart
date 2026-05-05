class ApiEndpoints {
  // ── Auth ──────────────────────────────────────────────────
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';

  // ── Projects ──────────────────────────────────────────────
  static const String projects = '/projects';
  static String projectById(int id) => '/projects/$id';
  static String projectDiagrams(int id) => '/projects/$id/diagrams';

  // ── Diagrams ──────────────────────────────────────────────
  static const String generateDiagram = '/diagrams/generate';
  static String diagramById(int id) => '/diagrams/$id';
}
