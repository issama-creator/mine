import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/hypno_colors.dart';
import 'fly_ball.dart';

enum PassageKind { arch, zigzag, wave, snake, ramp }

/// Glowing ghost geometry the player should trace — "wow" draw challenges.
class GuidePassage extends PositionComponent with HasGameReference {
  GuidePassage({
    required this.kind,
    required this.points,
    required this.ball,
    required this.cameraX,
    required this.onTraced,
    required this.label,
  });

  final PassageKind kind;
  final List<Offset> points; // world space
  final FlyBall ball;
  final double Function() cameraX;
  final void Function({required bool perfect}) onTraced;
  final String label;

  bool _started = false;
  bool _done = false;
  double _goodSamples = 0;
  double _totalSamples = 0;
  double _pulse = 0;

  static List<Offset> build({
    required PassageKind kind,
    required double startX,
    required double baseY,
    required math.Random rng,
  }) {
    switch (kind) {
      case PassageKind.arch:
        // Big hump over a gap
        return [
          for (var i = 0; i <= 14; i++)
            Offset(
              startX + i * 18,
              baseY - math.sin(i / 14 * math.pi) * (70 + rng.nextDouble() * 20),
            ),
        ];
      case PassageKind.zigzag:
        final pts = <Offset>[];
        var x = startX;
        var up = true;
        for (var i = 0; i < 6; i++) {
          pts.add(Offset(x, baseY + (up ? -55 : 25)));
          x += 45;
          up = !up;
        }
        pts.add(Offset(x, baseY));
        return pts;
      case PassageKind.wave:
        return [
          for (var i = 0; i <= 18; i++)
            Offset(
              startX + i * 16,
              baseY + math.sin(i / 3.0) * 38,
            ),
        ];
      case PassageKind.snake:
        return [
          for (var i = 0; i <= 16; i++)
            Offset(
              startX + i * 17,
              baseY - 20 + math.sin(i * 0.9) * 50 + math.cos(i * 0.4) * 12,
            ),
        ];
      case PassageKind.ramp:
        return [
          Offset(startX, baseY),
          Offset(startX + 60, baseY - 10),
          Offset(startX + 110, baseY - 70),
          Offset(startX + 160, baseY - 70),
          Offset(startX + 210, baseY + 10),
          Offset(startX + 260, baseY),
        ];
    }
  }

  static String titleOf(PassageKind k) => switch (k) {
        PassageKind.arch => 'ARCH',
        PassageKind.zigzag => 'ZIGZAG',
        PassageKind.wave => 'WAVE',
        PassageKind.snake => 'SNAKE',
        PassageKind.ramp => 'RAMP',
      };

  @override
  Future<void> onLoad() async {
    priority = 4;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt;
    if (_done || points.isEmpty) return;

    final start = points.first.dx;
    final end = points.last.dx;

    if (!_started && ball.worldX >= start - 20) {
      _started = true;
    }
    if (!_started) return;

    // Sample closeness while inside passage
    if (ball.worldX >= start && ball.worldX <= end) {
      _totalSamples += dt;
      final guideY = _heightAt(ball.worldX);
      if (guideY != null && (ball.worldY - guideY).abs() < 28) {
        _goodSamples += dt;
      }
    }

    if (ball.worldX > end + 10) {
      _done = true;
      final ratio =
          _totalSamples <= 0 ? 0.0 : (_goodSamples / _totalSamples);
      onTraced(perfect: ratio >= 0.62);
      removeFromParent();
    }

    if (points.last.dx - cameraX() < -80) {
      removeFromParent();
    }
  }

  double? _heightAt(double worldX) {
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      if (worldX >= a.dx && worldX <= b.dx) {
        final t = (worldX - a.dx) / (b.dx - a.dx).clamp(0.0001, 9999);
        return a.dy + (b.dy - a.dy) * t;
      }
    }
    return null;
  }

  @override
  void render(Canvas canvas) {
    if (points.length < 2) return;
    final cam = cameraX();
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final o = Offset(p.dx - cam, p.dy);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = HypnoColors.ring.withValues(alpha: 0.18 + 0.08 * math.sin(_pulse * 4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = HypnoColors.ring.withValues(alpha: 0.85);

    canvas.drawPath(path, glow);
    _drawDashed(canvas, path, dash);

    // Label at start
    final sx = points.first.dx - cam;
    final sy = points.first.dy - 36;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: HypnoColors.ring.withValues(alpha: 0.9),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(sx - tp.width / 2, sy));
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      const dashLen = 12.0;
      const gap = 8.0;
      var dist = 0.0;
      while (dist < metric.length) {
        final len = math.min(dashLen, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dashLen + gap;
      }
    }
  }
}
