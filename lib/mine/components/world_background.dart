import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/game_config.dart';
import '../managers/asset_manager.dart';
import '../managers/difficulty_manager.dart';
import '../models/mine_background.dart';

/// Decoration only. Painted bridges are shifted to [GameConfig.groundY].
/// Never drives gameplay Y.
class WorldBackground extends Component with HasGameReference {
  WorldBackground({
    required this.assets,
    required this.biomeManager,
    required this.difficulty,
  });

  final AssetManager assets;
  final BiomeManager biomeManager;
  final DifficultyManager difficulty;

  double _scroll = 0;

  static double _smoothstep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _scroll += dt * difficulty.bgScrollSpeed;
    biomeManager.update(dt);
  }

  void _drawScrollingLayer(
    Canvas canvas,
    Sprite sprite,
    double alpha,
    double roadOffset,
  ) {
    if (alpha <= 0.001) return;

    final worldW = GameConfig.worldWidth;
    final worldH = GameConfig.worldHeight;
    // Shift art so painted bridge top lands on the fixed ground line.
    final bgTop = GameConfig.groundY - roadOffset;
    final scale = worldH / sprite.image.height.toDouble();
    final dw = sprite.image.width.toDouble() * scale;
    final dh = worldH;
    final offset = (_scroll % dw + dw) % dw;

    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
    for (var x = -offset; x < worldW + dw; x += dw) {
      sprite.render(
        canvas,
        position: Vector2(x, bgTop),
        size: Vector2(dw, dh),
        overridePaint: paint,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final fromSprite = assets.bgAtIndex(biomeManager.fromBgIndex);
    final toSprite = assets.bgAtIndex(biomeManager.toBgIndex);
    if (fromSprite == null && toSprite == null) return;

    final fadeT = _smoothstep(biomeManager.transitionT);
    final fromOff = MineBackground.roadOffsetAt(biomeManager.fromBgIndex);
    final toOff = MineBackground.roadOffsetAt(biomeManager.toBgIndex);

    if (fromSprite != null) {
      _drawScrollingLayer(canvas, fromSprite, 1 - fadeT, fromOff);
    }
    if (toSprite != null) {
      _drawScrollingLayer(canvas, toSprite, fadeT, toOff);
    }

    if (biomeManager.isTransitioning && fadeT > 0.02 && fadeT < 0.98) {
      final dim = math.sin(math.pi * fadeT) * 0.18;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, GameConfig.worldWidth, GameConfig.worldHeight),
        Paint()..color = Color.fromRGBO(0, 0, 0, dim),
      );
    }
  }
}
