class AppConstants {
  // ── API ───────────────────────────────────────────────────
  // Android Emulator → 10.0.2.2 = localhost
  // Device حقيقي   → IP جهازك e.g. http://192.168.1.x:8000/api
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Secure Storage Keys ───────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ── Polling (diagram status) ──────────────────────────────
  static const Duration pollingInterval = Duration(seconds: 3);
  static const int maxPollingAttempts = 20; // 20 × 3s = 60s max

  // ── Diagram Types (API values) ────────────────────────────
  static const String typeAuto = 'auto';
  static const String typeClass = 'class';
  static const String typeErd = 'erd';
  static const String typeMindmap = 'mindmap';

  // ── Diagram Modes (API values) ────────────────────────────
  static const String modeGenerate = 'generate';
  static const String modeAnalyse = 'analyse';
  static const String modeExplain = 'explain';

  // ── Diagram Status (API values) ───────────────────────────
  static const String statusPending = 'pending';
  static const String statusProcessing = 'processing';
  static const String statusDone = 'done';
  static const String statusFailed = 'failed';

  // ── Misc ─────────────────────────────────────────────────
  static const int descriptionMaxLength = 1000;
}
