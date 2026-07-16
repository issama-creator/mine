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

/// Sprite torn in half — crate, beam, etc.
class SplitSpriteHalves extends PositionComponent {
  SplitSpriteHalves({
    required Vector2 at,
    required this.sprite,
    required this.objectSize,
    this.baseAngle = 0,
    this.gapSpeed = 155,
  }) : super(position: at.clone(), anchor: Anchor.center, priority: 20);

  final Sprite sprite;
  final Vector2 objectSize;
  final double baseAngle;
  final double gapSpeed;

  static const _duration = 0.72;
  double _t = 0;
  Vector2 _leftPos = Vector2.zero();
  Vector2 _rightPos = Vector2.zero();
  late Vector2 _leftVel;
  late Vector2 _rightVel;
  double _leftAngle = 0;
  double _rightAngle = 0;
  double _leftSpin = 0;
  double _rightSpin = 0;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    final along = baseAngle;
    _leftVel = Vector2(
      -math.cos(along) * gapSpeed * 0.55 - 55,
      -math.sin(along) * gapSpeed * 0.35 - 95,
    );
    _rightVel = Vector2(
      math.cos(along) * gapSpeed * 0.55 + 55,
      -math.sin(along) * gapSpeed * 0.35 - 95,
    );
    _leftSpin = -5.5 - rng.nextDouble() * 4;
    _rightSpin = 5.5 + rng.nextDouble() * 4;
    _leftAngle = baseAngle - 0.22;
    _rightAngle = baseAngle + 0.22;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _duration) {
      removeFromParent();
      return;
    }
    _leftPos += _leftVel * dt;
    _rightPos += _rightVel * dt;
    _leftVel.y += 340 * dt;
    _rightVel.y += 340 * dt;
    _leftAngle += _leftSpin * dt;
    _rightAngle += _rightSpin * dt;
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / _duration).clamp(0.0, 1.0);
    final paint = Paint()..color = Colors.white.withValues(alpha: a);
    final hw = objectSize.x * 0.5;
    final hh = objectSize.y * 0.5;

    canvas.save();
    canvas.translate(_leftPos.x, _leftPos.y);
    canvas.rotate(_leftAngle);
    canvas.clipRect(Rect.fromLTWH(-hw, -hh, hw, objectSize.y));
    sprite.render(
      canvas,
      size: objectSize,
      anchor: Anchor.center,
      overridePaint: paint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(_rightPos.x, _rightPos.y);
    canvas.rotate(_rightAngle);
    canvas.clipRect(Rect.fromLTWH(0, -hh, hw, objectSize.y));
    sprite.render(
      canvas,
      size: objectSize,
      anchor: Anchor.center,
      overridePaint: paint,
    );
    canvas.restore();
  }
}

/// Compact dynamite pop — slice kill, not full arena blast.
class DynamitePop extends PositionComponent {
  DynamitePop({required Vector2 at})
      : super(position: at.clone(), anchor: Anchor.center, priority: 22);

  double _t = 0;
  late final List<_P> _sparks;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    const colors = [
      Color(0xFFFF5722),
      Color(0xFFFF9800),
      Color(0xFFFFEB3B),
      Color(0xFF424242),
    ];
    _sparks = List.generate(14, (i) {
      final ang = rng.nextDouble() * math.pi * 2;
      final sp = 55 + rng.nextDouble() * 95;
      return _P(
        vx: math.cos(ang) * sp,
        vy: math.sin(ang) * sp,
        r: 2 + rng.nextDouble() * 3.5,
        color: colors[i % colors.length],
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.38) {
      removeFromParent();
      return;
    }
    for (final p in _sparks) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 120 * dt;
      p.vx *= 1 - dt * 2.2;
    }
  }

  @override
  void render(Canvas canvas) {
    final life = (1 - _t / 0.38).clamp(0.0, 1.0);
    final flashR = 18 + _t * 55;
    canvas.drawCircle(
      Offset.zero,
      flashR,
      Paint()
        ..color = const Color(0xFFFF9800).withValues(alpha: life * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    for (final p in _sparks) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r * life,
        Paint()..color = p.color.withValues(alpha: life * 0.95),
      );
    }
  }
}

/// Rock / boulder crumbles into chunky shards.
class RockCrushBurst extends PositionComponent {
  RockCrushBurst({
    required Vector2 at,
    this.heavy = false,
    Sprite? sprite,
    Vector2? objectSize,
  })  : _sprite = sprite,
        _size = objectSize ?? Vector2(56, 56),
        super(position: at.clone(), anchor: Anchor.center, priority: 18);

  final bool heavy;
  final Sprite? _sprite;
  final Vector2 _size;

  double _t = 0;
  late final List<_RockChunk> _chunks;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    final n = heavy ? 6 : 4;
    _chunks = List.generate(n, (i) {
      final ang = rng.nextDouble() * math.pi * 2;
      final sp = 120 + rng.nextDouble() * 110;
      return _RockChunk(
        vx: math.cos(ang) * sp,
        vy: math.sin(ang) * sp - 70,
        rot: rng.nextDouble() * math.pi,
        spin: (rng.nextDouble() - 0.5) * 14,
        scale: 0.35 + rng.nextDouble() * 0.45,
        warm: rng.nextDouble() < 0.5,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.75) {
      removeFromParent();
      return;
    }
    for (final c in _chunks) {
      c.x += c.vx * dt;
      c.y += c.vy * dt;
      c.vy += 380 * dt;
      c.rot += c.spin * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / 0.75).clamp(0.0, 1.0);
    final paint = Paint()..color = Colors.white.withValues(alpha: a);

    for (final c in _chunks) {
      canvas.save();
      canvas.translate(c.x, c.y);
      canvas.rotate(c.rot);
      canvas.scale(c.scale);
      if (_sprite != null) {
        canvas.clipRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: _size.x * 0.45,
            height: _size.y * 0.45,
          ),
        );
        _sprite.render(
          canvas,
          size: _size * 0.5,
          anchor: Anchor.center,
          overridePaint: paint,
        );
      } else {
        final col = c.warm
            ? const Color(0xFF8D6E63)
            : const Color(0xFFBCAAA4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 16, height: 12),
            const Radius.circular(3),
          ),
          Paint()..color = col.withValues(alpha: a),
        );
      }
      canvas.restore();
    }
  }
}

class _RockChunk {
  _RockChunk({
    required this.vx,
    required this.vy,
    required this.rot,
    required this.spin,
    required this.scale,
    required this.warm,
  });
  double x = 0, y = 0;
  double vx, vy, rot, spin, scale;
  bool warm;
}

/// Metal saw — shower of sparks on slice.
class SawSparkShower extends PositionComponent {
  SawSparkShower({required Vector2 at})
      : super(position: at.clone(), anchor: Anchor.center, priority: 20);

  double _t = 0;
  late final List<_Spark> _sparks;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    _sparks = List.generate(18, (i) {
      final ang = -math.pi * 0.15 + (rng.nextDouble() - 0.5) * math.pi * 1.2;
      final sp = 90 + rng.nextDouble() * 180;
      return _Spark(
        x: (rng.nextDouble() - 0.5) * 12,
        y: (rng.nextDouble() - 0.5) * 12,
        vx: math.cos(ang) * sp,
        vy: math.sin(ang) * sp,
        len: 4 + rng.nextDouble() * 10,
        hot: rng.nextDouble() < 0.55,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.45) {
      removeFromParent();
      return;
    }
    for (final s in _sparks) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 220 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / 0.45).clamp(0.0, 1.0);
    for (final s in _sparks) {
      final col = s.hot ? const Color(0xFFFFEB3B) : const Color(0xFFECEFF1);
      canvas.drawLine(
        Offset(s.x, s.y),
        Offset(s.x - s.vx * 0.018 * s.len, s.y - s.vy * 0.018 * s.len),
        Paint()
          ..color = col.withValues(alpha: a)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

class _Spark {
  _Spark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.len,
    required this.hot,
  });
  double x, y, vx, vy, len;
  bool hot;
}

/// Crystal / diamond — prismatic shimmer ring.
class CrystalShatterRing extends PositionComponent {
  CrystalShatterRing({required Vector2 at, this.golden = false})
      : super(position: at.clone(), anchor: Anchor.center, priority: 20);

  final bool golden;
  double _t = 0;
  late final List<_Prism> _shards;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    final base = golden
        ? const [Color(0xFFFFD54F), Color(0xFFFFECB3), Colors.white]
        : const [Color(0xFF80DEEA), Color(0xFF4DD0E1), Color(0xFFE1F5FE)];
    _shards = List.generate(10, (i) {
      final ang = i / 10 * math.pi * 2 + rng.nextDouble() * 0.4;
      final sp = 70 + rng.nextDouble() * 120;
      return _Prism(
        vx: math.cos(ang) * sp,
        vy: math.sin(ang) * sp - 40,
        rot: rng.nextDouble() * math.pi,
        spin: (rng.nextDouble() - 0.5) * 10,
        color: base[i % base.length],
        size: 5 + rng.nextDouble() * 7,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.8) {
      removeFromParent();
      return;
    }
    for (final s in _shards) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 90 * dt;
      s.rot += s.spin * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - _t / 0.8).clamp(0.0, 1.0);
    final ringR = 8 + _t * 90;
    canvas.drawCircle(
      Offset.zero,
      ringR,
      Paint()
        ..color = (golden ? const Color(0xFFFFEB3B) : const Color(0xFF80DEEA))
            .withValues(alpha: a * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    for (final s in _shards) {
      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rot);
      final path = Path()
        ..moveTo(0, -s.size)
        ..lineTo(s.size * 0.6, 0)
        ..lineTo(0, s.size)
        ..lineTo(-s.size * 0.6, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = s.color.withValues(alpha: a * 0.9),
      );
      canvas.restore();
    }
  }
}

class _Prism {
  _Prism({
    required this.vx,
    required this.vy,
    required this.rot,
    required this.spin,
    required this.color,
    required this.size,
  });
  double x = 0, y = 0;
  double vx, vy, rot, spin, size;
  Color color;
}

/// Spike block — stone/metal chips fly off.
class SpikeBreakBurst extends PositionComponent {
  SpikeBreakBurst({required Vector2 at})
      : super(position: at.clone(), anchor: Anchor.center, priority: 18);

  double _t = 0;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    for (var i = 0; i < 5; i++) {
      final ang = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi;
      final sp = 100 + rng.nextDouble() * 130;
      add(
        DebrisShard(
          at: Vector2.zero(),
          velocity: Vector2(math.cos(ang) * sp, math.sin(ang) * sp),
          color: rng.nextBool()
              ? const Color(0xFF78909C)
              : const Color(0xFF5D4037),
          shardSize: 8 + rng.nextDouble() * 6,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.6) removeFromParent();
  }
}

/// Wood beam splinters on slice.
class WoodSplinterBurst extends PositionComponent {
  WoodSplinterBurst({required Vector2 at})
      : super(position: at.clone(), anchor: Anchor.center, priority: 18);

  double _t = 0;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    for (var i = 0; i < 7; i++) {
      final ang = (rng.nextDouble() - 0.5) * math.pi * 1.4;
      final sp = 80 + rng.nextDouble() * 140;
      add(
        DebrisShard(
          at: Vector2.zero(),
          velocity: Vector2(math.cos(ang) * sp, math.sin(ang) * sp - 50),
          color: Color.lerp(
            const Color(0xFF6D4C41),
            const Color(0xFFBCAAA4),
            rng.nextDouble(),
          )!,
          shardSize: 6 + rng.nextDouble() * 10,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.7) removeFromParent();
  }
}

/// Spider guts splat.
class SpiderSplat extends PositionComponent {
  SpiderSplat({required Vector2 at, this.big = false})
      : super(position: at.clone(), anchor: Anchor.center, priority: 18);

  final bool big;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    final n = big ? 8 : 5;
    for (var i = 0; i < n; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final sp = 60 + rng.nextDouble() * (big ? 130 : 90);
      add(
        DebrisShard(
          at: Vector2.zero(),
          velocity: Vector2(math.cos(ang) * sp, math.sin(ang) * sp),
          color: rng.nextBool()
              ? const Color(0xFF7CB342)
              : const Color(0xFF33691E),
          shardSize: big ? 14 : 9,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > 0.75) removeFromParent();
  }
}
