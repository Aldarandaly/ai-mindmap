import 'package:flutter/material.dart';

class AppSizes {
  // ── Responsive helper ──────────────────────────────────────
  static late double _width;
  static late double _height;
  static late double _pixelRatio;

  static void init(BuildContext context) {
    final media = MediaQuery.of(context);
    _width      = media.size.width;
    _height     = media.size.height;
    _pixelRatio = media.devicePixelRatio;
  }

  // Screen size helpers
  static double get screenWidth  => _width;
  static double get screenHeight => _height;
  static bool get isSmall  => _width < 360;
  static bool get isMedium => _width >= 360 && _width < 414;
  static bool get isLarge  => _width >= 414;

  // ── Adaptive font sizes ────────────────────────────────────
  static double get fontXs  => isSmall ? 9  : 10;
  static double get fontSm  => isSmall ? 11 : 12;
  static double get fontMd  => isSmall ? 13 : 14;
  static double get fontLg  => isSmall ? 14 : 16;
  static double get fontXl  => isSmall ? 16 : 18;
  static double get fontXxl => isSmall ? 20 : 24;

  // ── Adaptive spacing ───────────────────────────────────────
  static double get xs  => isSmall ? 3  : 4;
  static double get sm  => isSmall ? 6  : 8;
  static double get md  => isSmall ? 12 : 16;
  static double get lg  => isSmall ? 18 : 24;
  static double get xl  => isSmall ? 24 : 32;
  static double get xxl => isSmall ? 36 : 48;

  // ── Border Radius ──────────────────────────────────────────
  static const double radiusSm    = 8;
  static const double radiusMd    = 12;
  static const double radiusLg    = 16;
  static const double radiusXl    = 24;
  static const double radiusRound = 100;

  // ── Button ─────────────────────────────────────────────────
  static double get buttonHeight   => isSmall ? 48 : 52;
  static double get buttonHeightSm => isSmall ? 36 : 40;

  // ── Input ──────────────────────────────────────────────────
  static double get inputHeight => isSmall ? 48 : 52;

  // ── Icon ───────────────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // ── Card ───────────────────────────────────────────────────
  static double get cardPadding => isSmall ? 12 : 16;
  static const double cardRadius = 16;

  // ── Screen padding ─────────────────────────────────────────
  static double get screenPadding => isSmall ? 16 : 20;
}