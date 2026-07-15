import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import '../systems/pulse_config.dart';
import '../systems/tunnel_space.dart';
import 'player_pulse.dart';

enum CollectibleKind { orb, ring, bolt, prism }

enum HazardKind {
  /// Hard barrier — switch lane only.
  wall,

  /// Brittle crystal — smash when FAT (not holding).
  brittle,

  /// Slim gate — slip when SLIM (holding).
  gate,

  /// Collectible.
  shard,

  /// Voluntary boost ring — speed + coins, harder next beat.
  boost,

  /// Looks safe (green glow) but deadly — fake lane trap.
  fakeWall,
}

class Hazard extends PositionComponent with HasGameReference {
  Hazard({
    required this.space,
    required this.kind,
    required this.lanes,
    required this.onPassed,
    required this.onHit,
    required this.onNearMiss,
    required this.onShard,
    required this.onSmash,
    required this.onFormWarn,
    this.onBoost,
    this.onHauntCaptured,
    this.collectible = CollectibleKind.orb,
    this.isHaunt = false,
    this.hauntPower = 1,
  });

  final TunnelSpace space;
  final HazardKind kind;
  final List<int> lanes;
  final CollectibleKind collectible;
  final void Function(Hazard h)? onBoost;
  final void Function(Hazard h)? onHauntCaptured;

  final void Function(Hazard h, {required bool perfect}) onPassed;
  final void Function(Hazard h) onHit;
  final void Function(Hazard h) onNearMiss;
  final void Function(Hazard h) onShard;
  final void Function(Hazard h) onSmash;
  final void Function(Hazard h) onFormWarn;

  /// Ghost of your last death.
  final bool isHaunt;
  final int hauntPower;

  double depth = PulseConfig.spawnDepth;
  bool resolved = false;
  bool nearMissed = false;
  bool warned = false;
  bool hauntCaptured = false;
  double spin = 0;
  /// Fever: gate slit breathes.
  double feverBreath = 0;

  @override
  Future<void> onLoad() async {
    priority = 5;
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    space.size = Size(game.size.x, game.size.y);
    spin += dt * 4;
  }

  void advance(double amount) {
    depth += amount;
    if (depth > 1.15 && !resolved) {
      removeFromParent();
      return;
    }
    _syncTransform();
  }

  void checkAgainst(PlayerPulse player) {
    if (resolved) return;

    final d = depth - PulseConfig.playerDepth;
    final abs = d.abs();
    final playerLane = player.laneBlend.round().clamp(0, 2);

    if (!warned &&
        depth < PulseConfig.playerDepth &&
        depth > PulseConfig.playerDepth - 0.16) {
      final wrong = switch (kind) {
        HazardKind.wall || HazardKind.fakeWall => lanes.contains(playerLane),
        HazardKind.gate =>
          lanes.contains(playerLane) && !player.isCollapsed,
        HazardKind.brittle =>
          lanes.contains(playerLane) && !player.isSmashReady,
        HazardKind.shard || HazardKind.boost => false,
      };
      if (wrong) {
        warned = true;
        onFormWarn(this);
      }
    }

    if (!nearMissed &&
        abs < PulseConfig.nearMissPad &&
        depth > PulseConfig.playerDepth - PulseConfig.nearMissPad) {
      if ((kind == HazardKind.wall || kind == HazardKind.fakeWall) &&
          !lanes.contains(playerLane)) {
        nearMissed = true;
        onNearMiss(this);
      }
      if (kind == HazardKind.brittle &&
          lanes.contains(playerLane) &&
          player.isSmashReady) {
        nearMissed = true;
        onNearMiss(this);
      }
      if (kind == HazardKind.gate &&
          lanes.contains(playerLane) &&
          player.isCollapsed) {
        nearMissed = true;
        onNearMiss(this);
      }
    }

    if (abs > PulseConfig.hitDepthPad) {
      if (!resolved &&
          depth > PulseConfig.playerDepth + PulseConfig.hitDepthPad) {
        resolved = true;
        if (kind == HazardKind.wall || kind == HazardKind.fakeWall) {
          onPassed(this, perfect: false);
          _tryCaptureHaunt(perfect: true);
        } else if (kind == HazardKind.gate && lanes.contains(playerLane)) {
          onPassed(this, perfect: player.isCollapsed);
          _tryCaptureHaunt(perfect: player.isCollapsed);
        } else if (kind == HazardKind.brittle && lanes.contains(playerLane)) {
          onPassed(this, perfect: false);
        }
        removeFromParent();
      }
      return;
    }

    if (kind == HazardKind.shard || kind == HazardKind.boost) {
      if (lanes.contains(playerLane)) {
        resolved = true;
        if (kind == HazardKind.boost) {
          onBoost?.call(this);
        } else {
          onShard(this);
        }
        removeFromParent();
      }
      return;
    }

    if (kind == HazardKind.wall || kind == HazardKind.fakeWall) {
      if (lanes.contains(playerLane)) {
        resolved = true;
        onHit(this);
      }
      return;
    }

    if (kind == HazardKind.brittle) {
      if (!lanes.contains(playerLane)) return;
      resolved = true;
      if (player.isSmashReady) {
        onSmash(this);
        _tryCaptureHaunt(perfect: true);
        removeFromParent();
      } else {
        onHit(this);
      }
      return;
    }

    if (kind == HazardKind.gate) {
      if (!lanes.contains(playerLane)) return;
      if (player.isCollapsed) return;
      resolved = true;
      onHit(this);
    }
  }

  void _tryCaptureHaunt({required bool perfect}) {
    if (!isHaunt || hauntCaptured || !perfect) return;
    hauntCaptured = true;
    onHauntCaptured?.call(this);
  }

  void _syncTransform() {
    final lane = lanes.length >= 2 ? lanes.first : lanes.first;
    final x = space.laneX(lane, depth);
    final y = space.depthY(depth);
    position = Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    final s = space.scaleAt(depth);
    if (s < 0.05) return;

    switch (kind) {
      case HazardKind.wall:
        _drawWall(canvas, s, fake: false);
      case HazardKind.fakeWall:
        _drawWall(canvas, s, fake: true);
      case HazardKind.brittle:
        _drawBrittle(canvas, s);
      case HazardKind.gate:
        _drawGate(canvas, s);
      case HazardKind.shard:
        _drawShard(canvas, s);
      case HazardKind.boost:
        _drawBoost(canvas, s);
    }
    if (isHaunt) _drawHauntAura(canvas, s);
  }

  void _drawHauntAura(Canvas canvas, double s) {
    final wobble = math.sin(spin * 3) * 4 * s;
    final pulse = 0.5 + 0.5 * math.sin(spin * 5);
    canvas.drawCircle(
      Offset(wobble, 0),
      28 * s + hauntPower * 3,
      Paint()
        ..color = const Color(0xFFB388FF).withValues(alpha: 0.18 + pulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: hauntPower > 1 ? 'HAUNT x$hauntPower' : 'HAUNT',
        style: TextStyle(
          color: const Color(0xFFE1BEE7).withValues(alpha: 0.9),
          fontSize: 9 * s + 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -42 * s - tp.height));
  }

  void _drawWall(Canvas canvas, double s, {required bool fake}) {
    for (final lane in lanes) {
      final cx = space.laneX(lane, depth) - position.x;
      final w = space.laneWidth(depth) * 0.94;
      final h = 32.0 * s + 22;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 0), width: w, height: h),
        Radius.circular(8 * s),
      );
      final colors = fake
          ? [
              PulseColors.gate.withValues(alpha: 0.6),
              PulseColors.pulse.withValues(alpha: 0.5),
              const Color(0xFF1A3A2A),
            ]
          : [
              PulseColors.hazardWarn,
              PulseColors.hazard,
              const Color(0xFF3A0A18),
            ];
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ).createShader(rect.outerRect),
      );
      if (fake) {
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = PulseColors.gate.withValues(alpha: 0.85),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: 'SAFE?',
            style: TextStyle(
              color: PulseColors.gate.withValues(alpha: 0.9),
              fontSize: 9 * s + 6,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, -h * 0.55 - tp.height));
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, -h * 0.32),
              width: w * 0.88,
              height: h * 0.18,
            ),
            Radius.circular(3 * s),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Colors.white.withValues(alpha: 0.3),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: '✕',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16 * s + 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, -tp.height / 2));
      }
    }
  }

  void _drawBrittle(Canvas canvas, double s) {
    for (final lane in lanes) {
      final cx = space.laneX(lane, depth) - position.x;
      final w = space.laneWidth(depth) * 0.78;
      final h = 34.0 * s + 16;
      final pulse = 0.5 + 0.5 * math.sin(spin * 5);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 0), width: w, height: h),
        Radius.circular(4 * s),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              PulseColors.smashHot.withValues(alpha: 0.55),
              PulseColors.smash.withValues(alpha: 0.75),
              const Color(0xFF5A2808),
            ],
          ).createShader(rect.outerRect),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = PulseColors.smashHot.withValues(alpha: 0.7 + pulse * 0.25),
      );

      final crack = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.45);
      canvas.drawLine(
        Offset(cx - w * 0.2, -h * 0.25),
        Offset(cx + w * 0.1, h * 0.2),
        crack,
      );
      canvas.drawLine(
        Offset(cx + w * 0.05, -h * 0.3),
        Offset(cx - w * 0.05, h * 0.28),
        crack,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: 'SMASH',
          style: TextStyle(
            color: PulseColors.smashHot.withValues(alpha: 0.85),
            fontSize: 9 * s + 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, -h * 0.55 - tp.height));
    }
  }

  void _drawGate(Canvas canvas, double s) {
    final lane = lanes.first;
    final cx = space.laneX(lane, depth) - position.x;
    final w = space.laneWidth(depth) * 0.85;
    final h = 52.0 * s + 24;

    final outer = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 0), width: w, height: h),
      Radius.circular(8 * s),
    );
    canvas.drawRRect(
      outer,
      Paint()..color = PulseColors.gate.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * s
        ..color = PulseColors.gate,
    );

    final slitW = w * (0.18 + feverBreath * 0.06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 0), width: slitW, height: h * 0.75),
        Radius.circular(4 * s),
      ),
      Paint()..color = PulseColors.voidDeep.withValues(alpha: 0.85),
    );

    final pulse = (math.sin(spin * 3) * 0.5 + 0.5);
    canvas.drawCircle(
      Offset(cx, -h * 0.55),
      4 + pulse * 3,
      Paint()..color = PulseColors.gate.withValues(alpha: 0.5 + pulse * 0.4),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'HOLD',
        style: TextStyle(
          color: PulseColors.gate.withValues(alpha: 0.9),
          fontSize: 9 * s + 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, -h * 0.72 - tp.height));
  }

  void _drawBoost(Canvas canvas, double s) {
    for (final lane in lanes) {
      final cx = space.laneX(lane, depth) - position.x;
      final r = 18.0 * s;
      final pulse = 0.5 + 0.5 * math.sin(spin * 6);
      canvas.drawCircle(
        Offset(cx, 0),
        r * 1.4,
        Paint()
          ..color = PulseColors.pulse.withValues(alpha: 0.25 + pulse * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        Offset(cx, 0),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 * s
          ..color = PulseColors.pulse.withValues(alpha: 0.85),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: 'BOOST',
          style: TextStyle(
            color: PulseColors.pulseHot.withValues(alpha: 0.9),
            fontSize: 8 * s + 6,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, -r - tp.height - 4));
    }
  }

  void _drawShard(Canvas canvas, double s) {
    for (final lane in lanes) {
      final cx = space.laneX(lane, depth) - position.x;
      canvas.save();
      canvas.translate(cx, 0);
      canvas.rotate(spin);
      switch (collectible) {
        case CollectibleKind.orb:
          canvas.drawCircle(
            Offset.zero,
            14 * s,
            Paint()
              ..color = PulseColors.coinGlow.withValues(alpha: 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
          canvas.drawCircle(
            Offset.zero,
            9 * s,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  PulseColors.coinGlow,
                  PulseColors.coin,
                  PulseColors.coin.withValues(alpha: 0.7),
                ],
              ).createShader(Rect.fromCircle(center: Offset.zero, radius: 9 * s)),
          );
        case CollectibleKind.ring:
          canvas.drawCircle(
            Offset.zero,
            12 * s,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5 * s
              ..color = PulseColors.coinGlow.withValues(alpha: 0.9),
          );
          canvas.drawCircle(
            Offset.zero,
            7 * s,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * s
              ..color = PulseColors.coin,
          );
        case CollectibleKind.bolt:
          final bolt = Path()
            ..moveTo(0, -12 * s)
            ..lineTo(5 * s, -1 * s)
            ..lineTo(0, -1 * s)
            ..lineTo(3 * s, 12 * s)
            ..lineTo(-5 * s, 2 * s)
            ..lineTo(0, 2 * s)
            ..close();
          canvas.drawPath(
            bolt,
            Paint()
              ..color = PulseColors.coinGlow.withValues(alpha: 0.5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          canvas.drawPath(bolt, Paint()..color = PulseColors.coinGlow);
        case CollectibleKind.prism:
          final path = Path()
            ..moveTo(0, -11 * s)
            ..lineTo(9 * s, 0)
            ..lineTo(0, 11 * s)
            ..lineTo(-9 * s, 0)
            ..close();
          canvas.drawPath(
            path,
            Paint()
              ..color = PulseColors.coin.withValues(alpha: 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          canvas.drawPath(path, Paint()..color = PulseColors.coinGlow);
      }
      canvas.restore();
    }
  }
}
