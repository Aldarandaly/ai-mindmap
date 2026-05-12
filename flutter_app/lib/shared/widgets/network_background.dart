import 'dart:math';
import 'package:flutter/material.dart';

class NetworkBackground extends StatefulWidget {
  final Widget child;
  const NetworkBackground({super.key, required this.child});

  @override
  State<NetworkBackground> createState() => _NetworkBackgroundState();
}

class _NetworkBackgroundState extends State<NetworkBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => CustomPaint(
        painter: _NetworkPainter(_animation.value),
        child: widget.child,
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final double animValue;
  _NetworkPainter(this.animValue);

  // Fixed nodes positions (relative 0..1)
  static const _nodes = [
    Offset(0.08, 0.12), Offset(0.25, 0.06), Offset(0.55, 0.04),
    Offset(0.80, 0.10), Offset(0.95, 0.22), Offset(0.90, 0.45),
    Offset(0.95, 0.68), Offset(0.78, 0.82), Offset(0.55, 0.92),
    Offset(0.30, 0.88), Offset(0.08, 0.75), Offset(0.04, 0.50),
    Offset(0.15, 0.35), Offset(0.38, 0.18), Offset(0.65, 0.22),
    Offset(0.72, 0.55), Offset(0.45, 0.70), Offset(0.22, 0.60),
  ];

  // Connections between nodes (index pairs)
  static const _edges = [
    [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6],
    [6, 7], [7, 8], [8, 9], [9, 10], [10, 11], [11, 12],
    [12, 13], [13, 14], [14, 15], [15, 16], [16, 17], [17, 12],
    [1, 13], [2, 14], [5, 15], [8, 16], [11, 17],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgPaint = Paint();
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    bgPaint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0D1B2A),
        Color(0xFF0D1428),
        Color(0xFF12082E),
        Color(0xFF1A0535),
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Glow orbs
    _drawOrb(canvas, size, 0.15, 0.25, 180, const Color(0xFF6C63FF), 0.12);
    _drawOrb(canvas, size, 0.80, 0.70, 220, const Color(0xFF9B59B6), 0.10);
    _drawOrb(canvas, size, 0.50, 0.10, 120, const Color(0xFF00D4FF), 0.08);

    final positions = _nodes.map((n) => Offset(n.dx * size.width, n.dy * size.height)).toList();

    // Draw edges
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final edge in _edges) {
      final a = positions[edge[0]];
      final b = positions[edge[1]];
      final dist = (b - a).distance;
      final alpha = (1.0 - dist / size.width).clamp(0.1, 0.35);
      edgePaint.color = Color.fromRGBO(108, 99, 255, alpha);
      canvas.drawLine(a, b, edgePaint);
    }

    // Draw nodes
    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final pulse = sin(animValue * 2 * pi + i * 0.8) * 0.5 + 0.5;
      final radius = 3.0 + pulse * 2.0;

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF6C63FF).withValues(alpha: 0.15 + pulse * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, radius * 2.5, glowPaint);

      // Node
      final nodePaint = Paint()
        ..color = Color.lerp(
          const Color(0xFF6C63FF),
          const Color(0xFF00D4FF),
          (i / _nodes.length),
        )!.withValues(alpha: 0.7 + pulse * 0.3);
      canvas.drawCircle(pos, radius, nodePaint);

      // Center dot
      canvas.drawCircle(pos, 1.5, Paint()..color = Colors.white.withValues(alpha: 0.6));
    }
  }

  void _drawOrb(Canvas canvas, Size size, double x, double y, double r, Color color, double alpha) {
    final pulse = sin(animValue * pi) * 0.3 + 0.7;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: alpha * pulse), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(x * size.width, y * size.height),
        radius: r,
      ));
    canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
  }

  @override
  bool shouldRepaint(_NetworkPainter old) => old.animValue != animValue;
}
