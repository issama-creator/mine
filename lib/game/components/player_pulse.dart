import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import '../pulse_skins.dart';
import '../systems/pulse_config.dart';
import '../systems/tunnel_space.dart';

/// Morphing pulse glyph — needle when slim, shield when smash.
class PlayerPulse extends PositionComponent with HasGameReference {
  PlayerPulse({required this.space});

  TunnelSpace space;

  int lane = 1;
  int _targetLane = 1;
  double _fromLane = 1;
  double _laneT = 1;
  double collapse = 0;
  bool wantCollapse = false;
  double _pulse = 0;
  final List<Offset> _trail = [];

  PulseSkin skin = PulseSkins.neon;

  /// 0 open/smash · 1 slim
  double get form => collapse;

  double get laneBlend =>
      _fromLane + (_targetLane - _fromLane) * _ease(_laneT.clamp(0.0, 1.0));

  bool get isCollapsed => collapse > 0.7;
  bool get isSmashReady => collapse < 0.28;

  double correctGlow = 0;
  double wrongOutline = 0;

  @override
  Future<void> onLoad() async {
    priority = 20;
    anchor = Anchor.center;
  }

  void moveLane(int delta) => setLane(_targetLane + delta);

  void setLane(int value) {
    final next = value.clamp(0, PulseConfig.laneCount - 1);
    if (next == _targetLane) return;
    _fromLane = laneBlend;
    _targetLane = next;
    lane = next;
    _laneT = 0;
  }

  void reset() {
    lane = 1;
    _targetLane = 1;
    _fromLane = 1;
    _laneT = 1;
    collapse = 0;
    wantCollapse = false;
    correctGlow = 0;
    wrongOutline = 0;
    _trail.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    space.size = Size(game.size.x, game.size.y);
    _pulse += dt * 8;

    if (_laneT < 1) {
      _laneT = (_laneT + dt / PulseConfig.laneSwitchSeconds).clamp(0.0, 1.0);
    }

    final target = wantCollapse ? 1.0 : 0.0;
    collapse +=
        (target - collapse) * (1 - math.exp(-PulseConfig.collapseLerp * dt));

    if (correctGlow > 0) correctGlow = (correctGlow - dt * 2.5).clamp(0.0, 1.0);
    if (wrongOutline > 0) {
      wrongOutline = (wrongOutline - dt * 2.8).clamp(0.0, 1.0);
    }

    final depth = PulseConfig.playerDepth;
    final lx = _laneXContinuous(laneBlend, depth);
    final y = space.depthY(depth);
    position = Vector2(lx, y);

    _trail.insert(0, Offset(lx, y));
    if (_trail.length > 22) _trail.removeLast();
  }

  double _laneXContinuous(double laneF, double depth) {
    final a = laneF.floor().clamp(0, 2);
    final b = laneF.ceil().clamp(0, 2);
    final t = laneF - a;
    return space.laneX(a, depth) * (1 - t) + space.laneX(b, depth) * t;
  }

  double _ease(double t) => t * t * (3 - 2 * t);

  /// Slim = tall needle · Smash = wide crystal shield.
  Path _glyphPath(double base, double c) {
    final w = base * (1.35 - c * 0.95);
    final h = base * (0.85 + c * 1.15);
    final smash = 1 - c;
    final notch = base * 0.22 * smash;

    return Path()
      ..moveTo(0, -h)
      ..lineTo(w * 0.55, -h * 0.12)
      ..lineTo(w, 0)
      ..lineTo(w * 0.55 + notch, h * 0.55)
      ..lineTo(0, h * (0.55 + smash * 0.2))
      ..lineTo(-w * 0.55 - notch, h * 0.55)
      ..lineTo(-w, 0)
      ..lineTo(-w * 0.55, -h * 0.12)
      ..close();
  }

  @override
  void render(Canvas canvas) {
    final s = space.scaleAt(PulseConfig.playerDepth);
    final base = 24.0 * s;
    final c = collapse;
    final smash = (1 - c).clamp(0.0, 1.0);
    final glyph = _glyphPath(base, c);
    final bodyColor = Color.lerp(skin.smash, skin.pulse, c)!;
    final hotColor = Color.lerp(skin.smashHot, skin.pulseHot, c)!;

    // Streak trail — laser line when slim, wide smear when smash
    for (var i = 1; i < _trail.length; i++) {
      final t = 1 - i / _trail.length;
      final from = _trail[i] - Offset(position.x, position.y);
      final to = _trail[i - 1] - Offset(position.x, position.y);
      final trailW = (1.5 + smash * 5) * t * s;
      canvas.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = trailW
          ..strokeCap = StrokeCap.round
          ..color = bodyColor.withValues(alpha: 0.08 * t + smash * 0.04 * t),
      );
    }

    if (wrongOutline > 0) {
      canvas.drawPath(
        glyph,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..color = PulseColors.hazard
              .withValues(alpha: 0.55 + wrongOutline * 0.4),
      );
    }

    if (correctGlow > 0) {
      canvas.drawPath(
        _glyphPath(base * (1.18 + correctGlow * 0.12), c),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = skin.gate.withValues(alpha: 0.5 + correctGlow * 0.45),
      );
    }

    // Outer aura — ellipse stretches with form
    final auraW = base * (2.0 + smash * 0.5);
    final auraH = base * (1.4 + c * 0.9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: auraW * (1 + math.sin(_pulse) * 0.08),
        height: auraH * (1 + math.sin(_pulse) * 0.08),
      ),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..color = Color.lerp(skin.smash, skin.gate, c)!
            .withValues(alpha: 0.22 + smash * 0.14),
    );

    // Spinning orbit shards — tighter when slim
    final orbitR = base * (1.05 + smash * 0.35);
    for (var i = 0; i < 3; i++) {
      final ang = _pulse * (1.6 + smash * 0.8) + i * math.pi * 2 / 3;
      final ox = math.cos(ang) * orbitR * (0.55 + smash * 0.45);
      final oy = math.sin(ang) * orbitR * (0.35 + c * 0.65);
      canvas.drawCircle(
        Offset(ox, oy),
        (2.5 + smash * 2) * s,
        Paint()..color = hotColor.withValues(alpha: 0.45 + smash * 0.25),
      );
    }

    // Core glyph body
    canvas.drawPath(
      glyph,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, -0.2 + c * 0.3),
          colors: [
            PulseColors.pulseCore,
            hotColor,
            bodyColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: base * 1.2)),
    );

    // Facet lines — crystal read
    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.25 + smash * 0.2);
    canvas.drawLine(Offset(0, -base * (0.85 + c * 1.1)), Offset.zero, facet);
    canvas.drawLine(Offset(-base * 0.5, 0), Offset(base * 0.5, 0), facet);

    // Form-specific accents
    if (isCollapsed) {
      canvas.drawPath(
        _glyphPath(base * 1.35, c),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = skin.gate.withValues(alpha: 0.7),
      );
      // Vertical laser core
      canvas.drawLine(
        Offset(0, -base * 1.4),
        Offset(0, base * 0.9),
        Paint()
          ..strokeWidth = 2.5 * s
          ..strokeCap = StrokeCap.round
          ..color = skin.pulseHot.withValues(alpha: 0.85),
      );
    } else if (isSmashReady) {
      final ring = 0.55 + 0.45 * math.sin(_pulse * 1.4);
      canvas.drawPath(
        _glyphPath(base * (1.4 + ring * 0.15), c),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = skin.smash.withValues(alpha: 0.55 * ring),
      );
    }
  }
}
