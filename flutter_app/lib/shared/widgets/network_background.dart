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

    canvas.drawRect(
      rect,
      Paint()..color = const Color.fromARGB(255, 26, 26, 46),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.70, -0.80),
          radius: 1.1,
          colors: [
            const Color.fromARGB(255, 153, 142, 255).withOpacity(0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.76, 0.70),
          radius: 0.9,
          colors: [
            const Color.fromARGB(255, 172, 145, 255).withOpacity(0.18),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.80, -0.70),
          radius: 0.8,
          colors: [
            const Color.fromARGB(255, 109, 167, 255).withOpacity(0.15),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

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
      Offset(0.40 * w, 0.17 * h),
      Offset(0.52 * w, 0.10 * h),
      Offset(0.11 * w, 0.19 * h),
      Offset(0.39 * w, 0.80 * h),
      Offset(0.03 * w, 0.42 * h),
      Offset(0.20 * w, 0.35 * h),
      Offset(0.47 * w, 0.28 * h),
      Offset(0.73 * w, 0.40 * h),
      Offset(0.60 * w, 0.55 * h),
      Offset(0.30 * w, 0.60 * h),
      Offset(0.15 * w, 0.50 * h),
      Offset(0.85 * w, 0.10 * h),
      Offset(0.70 * w, 0.25 * h),
      Offset(0.50 * w, 0.45 * h),
      Offset(0.22 * w, 0.72 * h),
      Offset(0.65 * w, 0.72 * h),
      Offset(0.44 * w, 0.65 * h),
      Offset(0.08 * w, 0.88 * h),
      Offset(0.78 * w, 0.60 * h),
      Offset(0.33 * w, 0.45 * h),
      Offset(0.57 * w, 0.33 * h),
      Offset(0.90 * w, 0.38 * h),
      Offset(0.18 * w, 0.05 * h),
      Offset(0.95 * w, 0.75 * h),
      Offset(0.42 * w, 0.95 * h),
    ];

    for (final dot in dotPositions) {
      canvas.drawCircle(dot, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_BgPainter oldDelegate) => false;
}