import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/hypno_colors.dart';
import 'fly_ball.dart';

enum HazardType { hole, fan, ring, spike, magnet }

class TrackHazard extends PositionComponent with HasGameReference {
  TrackHazard({
    required this.type,
    required this.worldX,
    required this.ball,
    required this.onHit,
    required this.onPerfect,
    required this.onClose,
    required this.cameraX,
    this.anchorY = 0,
    this.fakePullY,
  });

  final HazardType type;
  double worldX;
  final FlyBall ball;
  final VoidCallback onHit;
  final VoidCallback onPerfect;
  final VoidCallback onClose;
  final double Function() cameraX;
  final double anchorY;

  /// Where the hypno/"fake" line sits — magnet pulls toward this.
  final double? fakePullY;

  bool resolved = false;
  double spin = 0;

  @override
  Future<void> onLoad() async {
    priority = 10;
    anchor = Anchor.center;
    size = Vector2(50, 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    spin += dt * 4;
    position = Vector2(worldX - cameraX(), anchorY);

    if (resolved) {
      if (worldX - ball.worldX < -80) removeFromParent();
      return;
    }

    final dx = (ball.worldX - worldX).abs();
    if (dx > 40) {
      if (ball.worldX > worldX + 40) {
        // Missed interaction window
        if (type == HazardType.ring) {
          // no perfect
        }
        resolved = true;
      }
      return;
    }

    final dy = (ball.worldY - anchorY).abs();

    switch (type) {
      case HazardType.hole:
        // Hole = kill if ball is near its Y (on road through hole)
        if (dx < 28 && dy < 36 && !ball.falling) {
          resolved = true;
          onHit();
        }
      case HazardType.spike:
        if (dx < 26 && dy < 34) {
          resolved = true;
          onHit();
        }
      case HazardType.fan:
        if (dx < 50) {
          // Push ball up/down
          ball.worldY += math.sin(spin * 2) * 90 * dt;
          if (dx < 22 && dy < 20) {
            // skimmed fan closely
            if (!resolved) {
              resolved = true;
              onClose();
            }
          }
        }
      case HazardType.ring:
        if (dx < 18) {
          resolved = true;
          if (dy < 22) {
            onPerfect();
          } else if (dy < 40) {
            onClose();
          } else {
            onHit();
          }
        }
      case HazardType.magnet:
        if (dx < 70) {
          final target = fakePullY ?? (anchorY - 28);
          final pull = (70 - dx) / 70;
          ball.worldY += (target - ball.worldY) * 3.2 * pull * dt;
          if (dx < 20 && (ball.worldY - target).abs() < 16) {
            // Got baited into fake line — punish lightly as hit if deep in trap
            if ((ball.worldY - anchorY).abs() > 26) {
              resolved = true;
              onHit();
            } else if (!resolved && dx < 14) {
              resolved = true;
              onClose();
            }
          }
        }
    }
  }

  @override
  void render(Canvas canvas) {
    switch (type) {
      case HazardType.hole:
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 54, height: 22),
          Paint()..color = Colors.black.withValues(alpha: 0.85),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 54, height: 22),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = HypnoColors.hazard,
        );
      case HazardType.spike:
        final p = Path()
          ..moveTo(-14, 16)
          ..lineTo(0, -22)
          ..lineTo(14, 16)
          ..close();
        canvas.drawPath(p, Paint()..color = HypnoColors.hazard);
      case HazardType.fan:
        canvas.save();
        canvas.rotate(spin * 3);
        for (var i = 0; i < 3; i++) {
          canvas.rotate(2.094);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-6, -28, 12, 28),
              const Radius.circular(4),
            ),
            Paint()..color = HypnoColors.fan.withValues(alpha: 0.85),
          );
        }
        canvas.restore();
        canvas.drawCircle(Offset.zero, 6, Paint()..color = HypnoColors.ui);
      case HazardType.ring:
        canvas.drawCircle(
          Offset.zero,
          26,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = HypnoColors.ring,
        );
        canvas.drawCircle(
          Offset.zero,
          26,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..color = HypnoColors.ring.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      case HazardType.magnet:
        canvas.drawCircle(
          Offset.zero,
          18,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = HypnoColors.fake,
        );
        for (var i = 0; i < 6; i++) {
          final a = spin + i * math.pi / 3;
          canvas.drawLine(
            Offset(math.cos(a) * 10, math.sin(a) * 10),
            Offset(math.cos(a) * 26, math.sin(a) * 26),
            Paint()
              ..color = HypnoColors.fake.withValues(alpha: 0.7)
              ..strokeWidth = 2,
          );
        }
        // Fake pull marker above
        canvas.drawCircle(
          const Offset(0, -30),
          5,
          Paint()..color = HypnoColors.fake.withValues(alpha: 0.55),
        );
    }
  }
}

class FloatText extends PositionComponent {
  FloatText({required Vector2 at, required this.text, required this.color})
      : super(position: at.clone(), anchor: Anchor.center);

  final String text;
  final Color color;
  double age = 0;

  @override
  int get priority => 40;

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    position.y -= 50 * dt;
    if (age > 0.7) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (1 - age / 0.7).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: t),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

class BurstFx extends PositionComponent {
  BurstFx({required Vector2 at, required this.color})
      : super(position: at.clone(), anchor: Anchor.center);

  final Color color;
  double age = 0;
  final _rng = math.Random();
  late final parts = List.generate(12, (_) {
    final a = _rng.nextDouble() * math.pi * 2;
    final sp = 60 + _rng.nextDouble() * 120;
    return (Offset(math.cos(a) * sp, math.sin(a) * sp), 2.0 + _rng.nextDouble() * 3);
  });

  @override
  int get priority => 30;

  @override
  void update(double dt) {
    age += dt;
    if (age > 0.4) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = 1 - age / 0.4;
    for (final p in parts) {
      canvas.drawCircle(p.$1 * (1.2 - t), p.$2 * t, Paint()..color = color.withValues(alpha: t));
    }
  }
}
