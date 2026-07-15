import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../mine_runner_game.dart';
import '../systems/slice_system.dart';

/// Glowing swipe trail — only while slice mode (power crystal) is active.
class SwipeTrailComponent extends Component
    with HasGameReference<MineRunnerGame> {
  SwipeTrailComponent({required this.sliceSystem});

  final SliceSystem sliceSystem;

  @override
  int get priority => 25;

  @override
  void render(Canvas canvas) {
    if (!game.sliceModeActive && sliceSystem.fadedTrail.length < 2) return;
    if (!game.sliceModeActive && sliceSystem.trail.isEmpty) return;

    final faded = sliceSystem.fadedTrail;
    if (faded.length < 2) return;

    for (var i = 1; i < faded.length; i++) {
      final a = faded[i];
      final b = faded[i - 1];
      final alpha = (a.alpha + b.alpha) * 0.5;
      if (alpha <= 0.02) continue;
      final w = a.width * 1.05;

      canvas.drawLine(
        b.pos,
        a.pos,
        Paint()
          ..strokeWidth = w + 10
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFE082).withValues(alpha: alpha * 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawLine(
        b.pos,
        a.pos,
        Paint()
          ..strokeWidth = w + 4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF80DEEA).withValues(alpha: alpha * 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawLine(
        b.pos,
        a.pos,
        Paint()
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: alpha),
              const Color(0xFFB2EBF2).withValues(alpha: alpha * 0.9),
            ],
          ).createShader(Rect.fromPoints(b.pos, a.pos)),
      );
    }

    final live = sliceSystem.trail;
    if (live.length >= 2) {
      canvas.drawLine(
        live[live.length - 2],
        live.last,
        Paint()
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        live.last,
        4.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }
}
