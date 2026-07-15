import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/game_config.dart';

/// Red horizontal line at GroundY only. Green feet marker is drawn in miner.
class GroundDebugComponent extends PositionComponent {
  @override
  Future<void> onLoad() async {
    priority = 1000;
    anchor = Anchor.topLeft;
    position = Vector2.zero();
    size = Vector2(GameConfig.worldWidth, GameConfig.worldHeight);
  }

  @override
  void render(Canvas canvas) {
    if (!GameConfig.debugGround) return;

    canvas.drawLine(
      Offset(0, GameConfig.groundY),
      Offset(size.x, GameConfig.groundY),
      Paint()
        ..color = const Color(0xFFFF1744)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }
}
