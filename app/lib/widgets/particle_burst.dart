import 'dart:math';
import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// 起飞粒子爆炸效果 —— 替代原 HTML 里的 .particle 动画
class ParticleBurst extends StatefulWidget {
  final String emoji;
  final Offset center; // 屏幕坐标
  final int count;
  final VoidCallback? onComplete;

  const ParticleBurst({
    super.key,
    required this.emoji,
    required this.center,
    this.count = 30,
    this.onComplete,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _Particle(_rand));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.r.iconXl * 1.05;  // 粒子 emoji 大小跟屏幕走
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            t: _controller.value,
            center: widget.center,
            emoji: widget.emoji,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double velocity;
  final double scale;
  final double rotation;
  final double rotationSpeed;
  _Particle(Random r)
      : angle = r.nextDouble() * 2 * pi,
        velocity = 100 + r.nextDouble() * 200,
        scale = 0.6 + r.nextDouble() * 0.8,
        rotation = r.nextDouble() * 2 * pi,
        rotationSpeed = (r.nextDouble() - 0.5) * 6;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1
  final Offset center;
  final String emoji;
  final double fontSize;

  _ParticlePainter({
    required this.particles,
    required this.t,
    required this.center,
    required this.emoji,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();

    final opacity = (1 - t).clamp(0.0, 1.0);
    final scaleNow = (1.5 - t * 1.2).clamp(0.0, 1.5);

    for (final p in particles) {
      final dx = cos(p.angle) * p.velocity * t;
      final dy = sin(p.angle) * p.velocity * t;
      final rot = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(center.dx + dx, center.dy + dy);
      canvas.rotate(rot);
      canvas.scale(p.scale * scaleNow);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    if (opacity < 0.1) return;
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.t != t || old.fontSize != fontSize;
}