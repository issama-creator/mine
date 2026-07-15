import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/hypno_colors.dart';
import '../road_path.dart';

class FlyBall extends PositionComponent with HasGameReference {
  FlyBall({required this.road});

  final RoadPath road;

  double worldX = 0;
  double worldY = 0;
  double speed = 220;
  double spin = 0;
  bool alive = true;
  bool falling = false;
  double fallV = 0;
  bool trustMode = true;

  final List<Offset> trail = [];

  static const radius = 15.0;
  /// Ball sits mid-left so finger drawing stays near it (not far on the right).
  static const screenXFactor = 0.40;

  double get meters => worldX / 100.0;

  void reset(double startY) {
    worldX = 0;
    worldY = startY;
    speed = 220;
    alive = true;
    falling = false;
    fallV = 0;
    spin = 0;
    trail.clear();
    trustMode = true;
  }

  void applyTier(int tier) {
    speed = (220 + tier * 40).clamp(220, 520).toDouble();
    if (!trustMode) speed *= 1.18;
  }

  /// Rescue pad under ball.
  void placePad(RoadPath road) {
    final y = worldY + 8;
    road.addWorldPoint(Offset(worldX - 10, y), force: true);
    road.addWorldPoint(Offset(worldX + 110, y), force: true);
    falling = false;
    fallV = 0;
    worldY = y;
  }

  @override
  Future<void> onLoad() async {
    priority = 20;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive) return;

    worldX += speed * dt;
    spin += speed * dt * 0.06;

    final h = road.heightAt(
      worldX,
      maxGap: 58,
      pastExtrapolate: speed * 0.65,
    );
    if (h == null) {
      falling = true;
    } else {
      // Recover if path returns under us while slightly falling
      if (falling && (h - worldY).abs() < 42 && fallV < 520) {
        falling = false;
        fallV = 0;
      }
    }

    if (falling) {
      fallV += 1500 * dt;
      worldY += fallV * dt;
      if (worldY > game.size.y + 80) alive = false;
    } else if (h != null) {
      final k = trustMode ? 12.0 : 20.0;
      worldY += (h - worldY) * (1 - math.exp(-k * dt));
    }

    final sx = game.size.x * screenXFactor;
    position = Vector2(sx, worldY);

    trail.insert(0, Offset(sx, worldY));
    if (trail.length > 12) trail.removeLast();
  }

  @override
  void render(Canvas canvas) {
    final accent = trustMode ? HypnoColors.trust : HypnoColors.panic;

    for (var i = 1; i < trail.length; i++) {
      final t = 1 - i / trail.length;
      final o = trail[i];
      canvas.drawCircle(
        Offset(o.dx - position.x, o.dy - position.y),
        radius * t * 0.55,
        Paint()..color = accent.withValues(alpha: 0.14 * t),
      );
    }

    canvas.drawCircle(
      Offset.zero,
      radius * 1.8,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = HypnoColors.ball.withValues(alpha: 0.4),
    );

    canvas.save();
    canvas.rotate(spin);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [HypnoColors.ballCore, HypnoColors.ball, Color(0xFFFFB020)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.drawCircle(
      Offset(radius * 0.35, -radius * 0.25),
      3.2,
      Paint()..color = Colors.black26,
    );
    canvas.restore();

    // Mode ring
    canvas.drawCircle(
      Offset.zero,
      radius + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.7),
    );
  }
}
