import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BgPainter(),
      child: child,
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Base color
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF111118),
    );

    // Orb 1 — top left
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.70, -0.80),
          radius: 1.1,
          colors: [
            const Color(0xFF6358FF).withOpacity(0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Orb 2 — bottom right
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.76, 0.70),
          radius: 0.9,
          colors: [
            const Color(0xFF7C5CFC).withOpacity(0.18),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Orb 3 — top right
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.80, -0.70),
          radius: 0.7,
          colors: [
            const Color(0xFF4F8EFF).withOpacity(0.10),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Dots
    final dotPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.18);

    final dotPositions = [
      Offset(0.12 * w, 0.18 * h),
      Offset(0.35 * w, 0.08 * h),
      Offset(0.62 * w, 0.12 * h),
      Offset(0.88 * w, 0.22 * h),
      Offset(0.92 * w, 0.55 * h),
      Offset(0.80 * w, 0.82 * h),
      Offset(0.55 * w, 0.92 * h),
      Offset(0.25 * w, 0.88 * h),
      Offset(0.05 * w, 0.70 * h),
      Offset(0.08 * w, 0.42 * h),
    ];

    for (final dot in dotPositions) {
      canvas.drawCircle(dot, 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_BgPainter oldDelegate) => false;
}