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

    // 🔆 lighter base
    canvas.drawRect(
      rect,
      Paint()..color = const Color.fromARGB(255, 19, 19, 32),
    );

    // Orb 1 — softer purple
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.70, -0.80),
          radius: 1.1,
          colors: [
            const Color.fromARGB(255, 153, 142, 255).withOpacity(0.14),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Orb 2 — softer violet
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.76, 0.70),
          radius: 0.9,
          colors: [
            const Color.fromARGB(255, 172, 145, 255).withOpacity(0.10),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // 🌤 Orb 3 — softer blue
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.80, -0.70),
          radius: 0.8,
          colors: [
            const Color.fromARGB(255, 109, 167, 255).withOpacity(0.08),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // dots lighter
    final dotPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.10);

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
      Offset(0.40 * w, 0.17 * h),
      Offset(0.52 * w, 0.10 * h),
      Offset(0.11 * w, 0.19 * h),
      Offset(0.39 * w, 0.80 * h),
      Offset(0.03 * w, 0.42 * h),
    ];

    for (final dot in dotPositions) {
      canvas.drawCircle(dot, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_BgPainter oldDelegate) => false;
}