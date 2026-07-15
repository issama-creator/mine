import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BurstFx extends PositionComponent {
  BurstFx({
    required Vector2 at,
    required this.color,
    this.count = 12,
  }) : super(position: at.clone(), anchor: Anchor.center);

  final Color color;
  final int count;
  late final List<_P> _parts;
  double _age = 0;
  static const _life = 0.45;

  @override
  Future<void> onLoad() async {
    priority = 30;
    final rng = math.Random();
    _parts = List.generate(count, (_) {
      final a = rng.nextDouble() * math.pi * 2;
      final sp = 80 + rng.nextDouble() * 160;
      return _P(
        Vector2(math.cos(a) * sp, math.sin(a) * sp),
        2 + rng.nextDouble() * 3,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final p in _parts) {
      p.pos += p.vel * dt;
      p.vel *= 0.92;
    }
    if (_age >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = 1 - _age / _life;
    for (final p in _parts) {
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        p.r * t,
        Paint()..color = color.withValues(alpha: t),
      );
    }
  }
}

class FloatingText extends PositionComponent {
  FloatingText({
    required Vector2 at,
    required this.text,
    required this.color,
  }) : super(position: at.clone(), anchor: Anchor.center);

  final String text;
  final Color color;
  double _age = 0;

  @override
  int get priority => 40;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 40 * dt;
    if (_age > 0.7) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (1 - _age / 0.7).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: t),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

class _P {
  _P(this.vel, this.r) : pos = Vector2.zero();
  Vector2 pos;
  Vector2 vel;
  final double r;
}

/// Soft camera shake parent offset — applied by game.
class ScreenShake {
  double time = 0;
  double intensity = 0;
  final _rng = math.Random();

  void bang(double amount, {double duration = 0.18}) {
    intensity = math.max(intensity, amount);
    time = math.max(time, duration);
  }

  Offset update(double dt) {
    if (time <= 0) {
      intensity = 0;
      return Offset.zero;
    }
    time -= dt;
    final f = (time / 0.18).clamp(0.0, 1.0);
    return Offset(
      (_rng.nextDouble() - 0.5) * intensity * f,
      (_rng.nextDouble() - 0.5) * intensity * f * 0.8,
    );
  }
}
