import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/object_kind.dart';

/// Expanding white flash on slice impact.
class ImpactFlash extends PositionComponent {
  ImpactFlash({required Vector2 at, this.maxRadius = 48})
      : super(position: at, anchor: Anchor.center);

  final double maxRadius;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.12) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / 0.12).clamp(0.0, 1.0);
    final r = maxRadius * p;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: (1 - p) * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}

/// Physics debris shard — rock half or generic chunk.
class DebrisShard extends PositionComponent {
  DebrisShard({
    required Vector2 at,
    required this.velocity,
    required this.color,
    this.shardSize = 14,
  }) : super(position: at, anchor: Anchor.center);

  final Vector2 velocity;
  final Color color;
  final double shardSize;

  double _life = 0.7;
  double _vr = 0;
  double _angle = 0;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    _vr = (rng.nextDouble() - 0.5) * 12;
    _angle = rng.nextDouble() * math.pi;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }
    position += velocity * dt;
    velocity.y += 420 * dt;
    _angle += _vr * dt;
  }

  @override
  void render(Canvas canvas) {
    final a = (_life / 0.7).clamp(0.0, 1.0);
    canvas.save();
    canvas.rotate(_angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: shardSize, height: shardSize * 0.65),
        const Radius.circular(2),
      ),
      Paint()..color = color.withValues(alpha: a),
    );
    canvas.restore();
  }
}

/// Lightweight particle burst — no GC churn per frame.
class ParticleBurst extends PositionComponent {
  ParticleBurst({
    required Vector2 at,
    required this.colors,
    this.count = 12,
    this.speed = 140,
    this.spread = math.pi * 2,
    this.baseAngle = -math.pi / 2,
    this.life = 0.55,
  }) : super(position: at, anchor: Anchor.center);

  final List<Color> colors;
  final int count;
  final double speed;
  final double spread;
  final double baseAngle;
  final double life;

  late final List<_P> _parts;
  late double _lifeLeft;

  @override
  Future<void> onLoad() async {
    _lifeLeft = life;
    final rng = math.Random();
    _parts = List.generate(count, (i) {
      final ang = baseAngle + (rng.nextDouble() - 0.5) * spread;
      final sp = speed * (0.45 + rng.nextDouble() * 0.65);
      return _P(
        vx: math.cos(ang) * sp,
        vy: math.sin(ang) * sp,
        r: 2 + rng.nextDouble() * 4,
        color: colors[i % colors.length],
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeLeft -= dt;
    if (_lifeLeft <= 0) {
      removeFromParent();
      return;
    }
    for (final p in _parts) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 180 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final a = (_lifeLeft / life).clamp(0.0, 1.0);
    for (final p in _parts) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r * a,
        Paint()..color = p.color.withValues(alpha: a * 0.9),
      );
    }
  }
}

class _P {
  _P({
    required this.vx,
    required this.vy,
    required this.r,
    required this.color,
  });
  double x = 0, y = 0;
  double vx, vy, r;
  Color color;
}

/// Floating +score / PERFECT / COMBO text with scale pop.
class FloatingPopup extends PositionComponent {
  FloatingPopup({
    required Vector2 at,
    required this.text,
    required this.color,
    this.glow = false,
    this.big = false,
  }) : super(position: at, anchor: Anchor.center);

  final String text;
  final Color color;
  final bool glow;
  final bool big;

  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 42 * dt;
    if (_t > 0.85) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final life = (_t / 0.85).clamp(0.0, 1.0);
    var scale = 1.0;
    if (_t < 0.12) {
      scale = 0.6 + (_t / 0.12) * 0.55;
    } else if (_t < 0.22) {
      scale = 1.15 - ((_t - 0.12) / 0.1) * 0.15;
    }
    scale *= 1 - life * 0.15;
    final alpha = (1 - life).clamp(0.0, 1.0);

    canvas.save();
    canvas.scale(scale);

    if (glow) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color.withValues(alpha: alpha * 0.4),
            fontSize: big ? 28 : 20,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                blurRadius: 16,
                color: color.withValues(alpha: alpha * 0.8),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    }

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: big ? 26 : 18,
          fontWeight: FontWeight.w900,
          letterSpacing: big ? 2 : 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }
}

/// Soft sand / rubble cloud when a miss hits the path (~0.5s).
class GroundSandPuff extends PositionComponent {
  GroundSandPuff({required Vector2 at, required this.kind})
      : super(position: at, anchor: Anchor.center, priority: 12);

  final ObjectKind kind;
  static const _life = 0.5;
  double _t = 0;
  late final List<_SandMote> _motes;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    final n = kind == ObjectKind.rockLarge ? 14 : 10;
    _motes = List.generate(n, (i) {
      final side = (rng.nextDouble() - 0.5) * 54;
      return _SandMote(
        x: side * 0.35,
        y: -2 - rng.nextDouble() * 4,
        vx: side * (0.8 + rng.nextDouble() * 1.4),
        vy: -18 - rng.nextDouble() * 55,
        r: 1.2 + rng.nextDouble() * 2.8,
        warm: rng.nextDouble() < 0.55,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) {
      removeFromParent();
      return;
    }
    for (final m in _motes) {
      m.x += m.vx * dt;
      m.y += m.vy * dt;
      m.vy += 220 * dt;
      m.vx *= 1 - dt * 1.6;
    }
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / _life).clamp(0.0, 1.0);
    // Soft oval stain on the stones.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 36 + 28 * (1 - a),
        height: 10 + 4 * (1 - a),
      ),
      Paint()
        ..color = const Color(0xFF8D6E63).withValues(alpha: a * 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    for (final m in _motes) {
      final color =
          m.warm ? const Color(0xFFD7A574) : const Color(0xFFBCAAA4);
      canvas.drawCircle(
        Offset(m.x, m.y),
        m.r * (0.5 + 0.5 * a),
        Paint()
          ..color = color.withValues(alpha: a * 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
      );
    }
  }
}

class _SandMote {
  _SandMote({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.warm,
  });
  double x, y, vx, vy, r;
  bool warm;
}
