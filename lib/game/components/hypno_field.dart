import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/hypno_colors.dart';
import '../hypno_roll_game.dart';

/// Deep space backdrop — stars, nebulae, drifting planets (parallax).
class HypnoField extends Component with HasGameReference {
  HypnoField() {
    final rng = math.Random(42);
    _stars = [
      for (var i = 0; i < 90; i++)
        _Star(
          nx: rng.nextDouble(),
          ny: rng.nextDouble(),
          r: 0.4 + rng.nextDouble() * 1.6,
          twinkle: rng.nextDouble() * math.pi * 2,
          depth: 0.25 + rng.nextDouble() * 0.75,
          warm: rng.nextBool(),
        ),
    ];
    _planets = const [
      _Planet(
        kind: _PlanetKind.gas,
        nx: 0.78,
        ny: 0.22,
        radius: 54,
        parallax: 0.12,
        base: Color(0xFFFF8A5C),
        accent: Color(0xFFE85D4C),
        hasRing: true,
      ),
      _Planet(
        kind: _PlanetKind.ice,
        nx: 0.18,
        ny: 0.68,
        radius: 38,
        parallax: 0.22,
        base: Color(0xFF7EC8FF),
        accent: Color(0xFF3A7CA5),
        hasRing: false,
      ),
      _Planet(
        kind: _PlanetKind.rocky,
        nx: 0.62,
        ny: 0.72,
        radius: 22,
        parallax: 0.35,
        base: Color(0xFFC4A77D),
        accent: Color(0xFF8B5E3C),
        hasRing: false,
      ),
      _Planet(
        kind: _PlanetKind.neon,
        nx: 0.88,
        ny: 0.58,
        radius: 16,
        parallax: 0.48,
        base: Color(0xFFB388FF),
        accent: Color(0xFF5CE1FF),
        hasRing: true,
      ),
      _Planet(
        kind: _PlanetKind.gas,
        nx: 0.08,
        ny: 0.18,
        radius: 28,
        parallax: 0.18,
        base: Color(0xFF9B6BFF),
        accent: Color(0xFF5B2C8A),
        hasRing: false,
      ),
    ];
  }

  double time = 0;
  double intensity = 1; // panic boosts this

  late final List<_Star> _stars;
  late final List<_Planet> _planets;

  @override
  int get priority => -20;

  @override
  void update(double dt) {
    super.update(dt);
    time += dt * (0.85 + intensity * 0.15);
  }

  double get _cam {
    final g = game;
    if (g is HypnoRollGame) return g.cameraX;
    return 0;
  }

  @override
  void render(Canvas canvas) {
    final size = game.size.toSize();
    final w = size.width;
    final h = size.height;

    // Deep space wash
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.35, h * 0.3),
          math.max(w, h) * 0.95,
          const [
            Color(0xFF1A1040),
            Color(0xFF0B0720),
            HypnoColors.voidBg,
          ],
          const [0.0, 0.45, 1.0],
        ),
    );

    // Soft nebulae
    _nebula(
      canvas,
      Offset(w * 0.7 + math.sin(time * 0.15) * 12, h * 0.25),
      w * 0.55,
      const Color(0xFF5B2C8A),
      0.14 * intensity.clamp(0.7, 1.5),
    );
    _nebula(
      canvas,
      Offset(w * 0.2 + math.cos(time * 0.12) * 10, h * 0.75),
      w * 0.48,
      const Color(0xFF1B4F72),
      0.12 * intensity.clamp(0.7, 1.5),
    );
    _nebula(
      canvas,
      Offset(w * 0.5, h * 0.55),
      w * 0.35,
      const Color(0xFF4A1942),
      0.08,
    );

    final cam = _cam;

    // Stars (parallax)
    for (final s in _stars) {
      final px = ((s.nx * w * 1.4 - cam * s.depth * 0.08) % (w + 40)) - 20;
      final py = s.ny * h + math.sin(time * 0.7 + s.twinkle) * 1.5;
      final tw =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(time * 2.2 + s.twinkle));
      final color = s.warm
          ? const Color(0xFFFFE4C4)
          : const Color(0xFFE8F0FF);
      canvas.drawCircle(
        Offset(px, py),
        s.r * (0.85 + 0.15 * intensity),
        Paint()..color = color.withValues(alpha: 0.25 + 0.55 * tw * s.depth),
      );
      if (s.r > 1.4) {
        canvas.drawCircle(
          Offset(px, py),
          s.r * 2.2,
          Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
            ..color = color.withValues(alpha: 0.12 * tw),
        );
      }
    }

    // Distant galaxy smudge
    final gx = w * 0.42 - (cam * 0.02) % 40;
    canvas.save();
    canvas.translate(gx, h * 0.38);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 120, height: 28),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..color = const Color(0xFFD4A5FF).withValues(alpha: 0.1),
    );
    canvas.restore();

    // Planets
    for (final p in _planets) {
      _drawPlanet(canvas, p, w, h, cam);
    }

    // Subtle vignette so the road reads cleaner
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.55),
          math.max(w, h) * 0.72,
          [
            const Color(0x00000000),
            Colors.black.withValues(alpha: 0.35 + 0.1 * (intensity - 1).clamp(0, 1)),
          ],
          const [0.55, 1.0],
        ),
    );
  }

  void _nebula(Canvas canvas, Offset c, double r, Color color, double a) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.45)
        ..color = color.withValues(alpha: a),
    );
  }

  void _drawPlanet(
    Canvas canvas,
    _Planet p,
    double w,
    double h,
    double cam,
  ) {
    final drift = math.sin(time * 0.2 + p.nx * 6) * 6;
    final x = ((p.nx * w - cam * p.parallax) % (w * 1.35 + p.radius * 2)) -
        p.radius;
    final y = p.ny * h + drift;
    final c = Offset(x, y);
    final r = p.radius;

    // Soft atmosphere glow
    canvas.drawCircle(
      c,
      r * 1.45,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35)
        ..color = p.base.withValues(alpha: 0.22),
    );

    if (p.hasRing) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.35 + math.sin(time * 0.15) * 0.05);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..color = p.accent.withValues(alpha: 0.55);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.8, height: r * 0.7),
        ring,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 3.15, height: r * 0.85),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.restore();
    }

    // Body
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-r * 0.35, -r * 0.4),
          r * 1.35,
          [
            Color.lerp(Colors.white, p.base, 0.35)!,
            p.base,
            p.accent,
            Color.lerp(p.accent, Colors.black, 0.45)!,
          ],
          const [0.0, 0.35, 0.7, 1.0],
        ),
    );

    // Surface details
    switch (p.kind) {
      case _PlanetKind.gas:
        for (var i = 0; i < 4; i++) {
          final yy = c.dy - r * 0.55 + i * r * 0.35;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(c.dx, yy),
              width: r * 1.7,
              height: r * 0.22,
            ),
            Paint()
              ..color = p.accent.withValues(alpha: 0.18 + i * 0.04)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
      case _PlanetKind.ice:
        canvas.drawCircle(
          c.translate(-r * 0.2, -r * 0.15),
          r * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.2),
        );
      case _PlanetKind.rocky:
        for (var i = 0; i < 5; i++) {
          final a = time * 0.05 + i * 1.3;
          canvas.drawCircle(
            Offset(c.dx + math.cos(a) * r * 0.35, c.dy + math.sin(a * 1.3) * r * 0.3),
            r * (0.08 + (i % 3) * 0.04),
            Paint()..color = p.accent.withValues(alpha: 0.35),
          );
        }
      case _PlanetKind.neon:
        canvas.drawCircle(
          c,
          r * 0.92,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = p.accent.withValues(alpha: 0.55),
        );
    }

    // Terminator shadow
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx - r, c.dy),
          Offset(c.dx + r, c.dy),
          [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
          ],
          const [0.35, 1.0],
        ),
    );
  }
}

enum _PlanetKind { gas, ice, rocky, neon }

class _Star {
  _Star({
    required this.nx,
    required this.ny,
    required this.r,
    required this.twinkle,
    required this.depth,
    required this.warm,
  });
  final double nx, ny, r, twinkle, depth;
  final bool warm;
}

class _Planet {
  const _Planet({
    required this.kind,
    required this.nx,
    required this.ny,
    required this.radius,
    required this.parallax,
    required this.base,
    required this.accent,
    required this.hasRing,
  });
  final _PlanetKind kind;
  final double nx, ny, radius, parallax;
  final Color base, accent;
  final bool hasRing;
}
