import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import '../systems/pulse_config.dart';
import '../systems/tunnel_space.dart';

/// Pseudo-3D space tunnel with stars, planets, and ribbing.
class TunnelBackdrop extends Component with HasGameReference {
  TunnelBackdrop({required this.space}) {
    final rng = math.Random(7);
    _stars = [
      for (var i = 0; i < 70; i++)
        _Star(
          nx: rng.nextDouble(),
          ny: rng.nextDouble() * 0.72,
          r: 0.5 + rng.nextDouble() * 1.4,
          tw: rng.nextDouble() * math.pi * 2,
        ),
    ];
  }

  TunnelSpace space;
  double scroll = 0;
  /// 0..1 beat phase from game (rhythm pulse).
  double beatPhase = 0;
  bool feverActive = false;
  double feverIntensity = 1.0;
  double warnFlash = 0;
  late final List<_Star> _stars;

  @override
  int get priority => -10;

  @override
  void update(double dt) {
    super.update(dt);
    space.size = Size(game.size.x, game.size.y);
    scroll += dt;
  }

  @override
  void render(Canvas canvas) {
    final size = space.size;
    final vp = space.vanishing;

    // Deep space fill
    final bg = Paint()
      ..shader = RadialGradient(
        center: Alignment(0, -0.55),
        radius: 1.15,
        colors: const [
          Color(0xFF141E32),
          PulseColors.voidMid,
          PulseColors.voidDeep,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Distant planets
    _planet(
      canvas,
      Offset(size.width * 0.18, size.height * 0.16),
      28,
      const Color(0xFFFF8A5C),
      const Color(0xFFE85D4C),
      ring: true,
    );
    _planet(
      canvas,
      Offset(size.width * 0.84, size.height * 0.22),
      16,
      const Color(0xFF7EC8FF),
      const Color(0xFF3A7CA5),
    );
    _planet(
      canvas,
      Offset(size.width * 0.72, size.height * 0.08),
      10,
      const Color(0xFFB388FF),
      const Color(0xFF5B2C8A),
    );

    // Stars
    for (final s in _stars) {
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(scroll * 2.4 + s.tw));
      canvas.drawCircle(
        Offset(s.nx * size.width, s.ny * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: 0.25 + 0.5 * tw),
      );
    }

    // Rhythm pulse — tunnel breathes with the beat
    final beat = 0.5 + 0.5 * math.sin(beatPhase * math.pi * 2);
    final feverMul = feverActive ? feverIntensity : 1.0;
    if (beat > 0.82 || feverActive) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = (feverActive ? PulseColors.gate : PulseColors.pulse)
              .withValues(alpha: 0.04 * beat * feverMul),
      );
    }
    if (warnFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = PulseColors.hazard.withValues(alpha: 0.12 * warnFlash),
      );
    }

    // Lane floors
    for (var lane = 0; lane < PulseConfig.laneCount; lane++) {
      final path = Path()
        ..moveTo(vp.dx, vp.dy)
        ..lineTo(space.laneX(lane, 1) - space.laneWidth(1) * 0.38, size.height)
        ..lineTo(space.laneX(lane, 1) + space.laneWidth(1) * 0.38, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = PulseColors.lane.withValues(alpha: 0.35 + lane * 0.04),
      );
    }

    // Center lane highlight
    final mid = Path()
      ..moveTo(vp.dx, vp.dy)
      ..lineTo(space.laneX(1, 1) - space.laneWidth(1) * 0.32, size.height)
      ..lineTo(space.laneX(1, 1) + space.laneWidth(1) * 0.32, size.height)
      ..close();
    canvas.drawPath(mid, Paint()..color = PulseColors.laneGlow);

    // Moving tunnel rings (depth cues)
    for (var i = 0; i < 14; i++) {
      final d = ((i / 14) + (scroll * 0.35) % 1.0) % 1.0;
      if (d < 0.04) continue;
      final y = space.depthY(d);
      final halfW = space.laneWidth(d) * 1.65;
      final alpha = (0.04 + 0.22 * d + beat * 0.06 * feverMul).clamp(0.0, 0.38);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.5 + 4 * d) * (1 + beat * 0.15 * feverMul)
        ..color = Color.lerp(
          PulseColors.pulse,
          feverActive ? PulseColors.gate : PulseColors.pulse,
          feverActive ? beat * 0.5 : 0,
        )!.withValues(alpha: alpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(vp.dx, y), width: halfW * 2.2, height: 10 + 40 * d),
          Radius.circular(6 + 20 * d),
        ),
        paint,
      );
    }

    // Side glow strips
    final leftGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          PulseColors.pulse.withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.18, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.18, size.height), leftGlow);

    final rightGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          PulseColors.hazard.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.82, 0, size.width * 0.18, size.height));
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.82, 0, size.width * 0.18, size.height),
      rightGlow,
    );

    // Vanishing core
    canvas.drawCircle(
      vp,
      6 + math.sin(scroll * 4) * 1.5,
      Paint()..color = PulseColors.pulse.withValues(alpha: 0.35),
    );
  }

  void _planet(
    Canvas canvas,
    Offset c,
    double r,
    Color base,
    Color accent, {
    bool ring = false,
  }) {
    canvas.drawCircle(
      c,
      r * 1.35,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4)
        ..color = base.withValues(alpha: 0.2),
    );
    if (ring) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.35);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2.7, height: r * 0.65),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..color = accent.withValues(alpha: 0.5),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 1.1,
          colors: [
            Color.lerp(Colors.white, base, 0.35)!,
            base,
            accent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }
}

class _Star {
  _Star({
    required this.nx,
    required this.ny,
    required this.r,
    required this.tw,
  });
  final double nx, ny, r, tw;
}
