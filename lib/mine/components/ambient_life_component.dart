import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/game_config.dart';
import '../mine_runner_game.dart';

/// Ambient mine life — stride dust, lamp cone, grit, ceiling sand.
class AmbientLifeComponent extends Component
    with HasGameReference<MineRunnerGame> {
  AmbientLifeComponent({required this.rng});

  final math.Random rng;

  final List<_Dust> _foot = [];
  final List<_Dust> _air = [];
  final List<_Sand> _sand = [];
  double _airAcc = 0;
  double _sandAcc = 0;
  double _lampPulse = 0;
  bool _wasPlant = false;

  @override
  int get priority => 16;

  @override
  void update(double dt) {
    super.update(dt);
    final g = game;
    if (!g.running.value || g.isGameOver || g.pauseMenu.value) return;
    if (!g.miner.isMounted) return;

    _lampPulse += dt;

    // Tiny boot puff on plant — just a hint he is stomping the stones.
    final planted = g.miner.isFootPlant;
    if (planted && !_wasPlant) {
      final feet = g.miner.position;
      final n = 1 + rng.nextInt(2); // 1–2 motes
      for (var i = 0; i < n; i++) {
        _foot.add(
          _Dust(
            x: feet.x + rng.nextDouble() * 10 - 8,
            y: feet.y - 0.5 - rng.nextDouble() * 1.5,
            vx: -18 - rng.nextDouble() * 28,
            vy: -3 - rng.nextDouble() * 10,
            life: 0.18 + rng.nextDouble() * 0.14,
            r: 0.8 + rng.nextDouble() * 1.2,
            warm: rng.nextDouble() < 0.4,
          ),
        );
      }
    }
    _wasPlant = planted;

    _airAcc += dt;
    if (_airAcc >= 0.14) {
      _airAcc = 0;
      final s = g.size;
      _air.add(
        _Dust(
          x: s.x * (0.2 + rng.nextDouble() * 0.75),
          y: s.y * (0.15 + rng.nextDouble() * 0.55),
          vx: -18 - rng.nextDouble() * 32,
          vy: 6 + rng.nextDouble() * 16,
          life: 1.2 + rng.nextDouble() * 1.4,
          r: 1 + rng.nextDouble() * 1.6,
          warm: false,
        ),
      );
    }

    _sandAcc += dt;
    if (_sandAcc >= 1.5 + rng.nextDouble() * 2.2) {
      _sandAcc = 0;
      final s = g.size;
      final x = s.x * (0.15 + rng.nextDouble() * 0.7);
      for (var i = 0; i < 3 + rng.nextInt(4); i++) {
        _sand.add(
          _Sand(
            x: x + rng.nextDouble() * 24 - 12,
            y: -8,
            vy: 70 + rng.nextDouble() * 90,
            life: 1.4 + rng.nextDouble(),
          ),
        );
      }
    }

    void tickDust(List<_Dust> list) {
      for (final d in list) {
        d.life -= dt;
        d.x += d.vx * dt;
        d.y += d.vy * dt;
        d.vy += 48 * dt;
        d.vx *= 1 - dt * 0.35;
      }
      list.removeWhere((d) => d.life <= 0);
    }

    tickDust(_foot);
    tickDust(_air);
    for (final s in _sand) {
      s.life -= dt;
      s.y += s.vy * dt;
      s.vy += 30 * dt;
    }
    _sand.removeWhere((s) => s.life <= 0 || s.y > GameConfig.worldHeight);

    while (_foot.length > 48) {
      _foot.removeAt(0);
    }
    while (_air.length > 40) {
      _air.removeAt(0);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.miner.isMounted) return;

    final miner = game.miner;
    final lamp = miner.lampWorld;
    final feet = miner.position;
    final pulse = 0.62 + 0.14 * math.sin(_lampPulse * 2.6);

    // Soft path contact spill under boots (sells “standing on stone”).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(feet.x - 4, feet.y - 2),
        width: miner.size.x * 0.58,
        height: 14,
      ),
      Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: 0.10 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Lamp halo + forward cone (headlamp looking along the run).
    canvas.drawCircle(
      Offset(lamp.x, lamp.y),
      52,
      Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      Offset(lamp.x, lamp.y),
      16,
      Paint()
        ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.32 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final cone = Path()
      ..moveTo(lamp.x + 4, lamp.y)
      ..lineTo(lamp.x + 110, lamp.y - 28)
      ..lineTo(lamp.x + 125, lamp.y + 36)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.07 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    for (final d in _foot) {
      final a = (d.life / 0.28).clamp(0.0, 1.0);
      final color = d.warm
          ? const Color(0xFFC4A484)
          : const Color(0xFFB0A090);
      canvas.drawCircle(
        Offset(d.x, d.y),
        d.r * (0.6 + 0.4 * a),
        Paint()
          ..color = color.withValues(alpha: a * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
    for (final d in _air) {
      final a = (d.life / 1.8).clamp(0.0, 1.0) * 0.32;
      canvas.drawCircle(
        Offset(d.x, d.y),
        d.r,
        Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: a),
      );
    }
    for (final s in _sand) {
      final a = (s.life / 1.5).clamp(0.0, 1.0) * 0.6;
      canvas.drawCircle(
        Offset(s.x, s.y),
        1.3,
        Paint()..color = const Color(0xFFA1887F).withValues(alpha: a),
      );
    }
  }
}

class _Dust {
  _Dust({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.r,
    required this.warm,
  });
  double x, y, vx, vy, life, r;
  bool warm;
}

class _Sand {
  _Sand({
    required this.x,
    required this.y,
    required this.vy,
    required this.life,
  });
  double x, y, vy, life;
}
