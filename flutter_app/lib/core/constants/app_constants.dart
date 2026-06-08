import 'package:flutter/foundation.dart';

class AppConstants {
  // ── API ───────────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    return 'https://ai-mindmap-production.up.railway.app/api';
  }

  static String get pythonUrl {
    if (kIsWeb) return 'http://localhost:8003';
    return 'https://fabulous-dedication-production-926e.up.railway.app';
  }

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ── Secure Storage Keys ───────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ── Polling (diagram status) ──────────────────────────────
  static const Duration pollingInterval = Duration(seconds: 3);
  static const int maxPollingAttempts = 20;

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
