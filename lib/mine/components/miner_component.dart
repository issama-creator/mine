import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/game_config.dart';
import '../managers/asset_manager.dart';
import '../mine_runner_game.dart';

/// Miner IS the sprite. Position = feet. Anchor = bottomCenter.
/// No nested sprite child (Flame local 0,0 is top-left of parent — that was
/// floating the run animation above GroundY).
class MinerComponent extends SpriteAnimationComponent
    with HasGameReference<MineRunnerGame> {
  MinerComponent({required this.assets});

  final AssetManager assets;
  double _runT = 0;

  double get hitH => math.max(size.y, GameConfig.minerTargetHeight);
  double get hitW => math.max(size.x, hitH * 0.85);

  void slicePulse() {}

  Vector2 get lampWorld =>
      position + Vector2(hitW * 0.06, -hitH * 0.82);

  Vector2 get headCenter => Vector2(0, -hitH * 0.86);
  double get headRadius => hitH * 0.35;
  Vector2 get headWorld => position + headCenter;

  void _lockFeet() {
    anchor = Anchor.bottomCenter;
    position.x = GameConfig.minerX;
    position.y = GameConfig.groundY;
    angle = 0;
    scale.setValues(1, 1);
  }

  @override
  void update(double dt) {
    _lockFeet();
    _ensureBodySize();
    super.update(dt);
    _lockFeet();
    _runT += dt;
  }

  void _ensureBodySize() {
    if (assets.runFrames.isEmpty) return;
    final frame = assets.runFrames.first;
    final s = assets.runFrameScale(frame);
    final want = frame.srcSize * s;
    if ((size.x - want.x).abs() > 1 || (size.y - want.y).abs() > 1) {
      size.setFrom(want);
    }
  }

  Rect get hurtBox {
    final f = position;
    final w = hitW;
    final h = hitH;
    final core = Rect.fromLTRB(
      f.x - w * 0.56,
      f.y - h * 0.96,
      f.x + w * 0.40,
      f.y + h * 0.02,
    );
    return core.inflate(GameConfig.minerHurtPadPx);
  }

  Rect get bodyHitBox => hurtBox;
  Rect get crownHitBox => hurtBox;

  bool isHitBy(
    Vector2 objPos,
    Vector2 objSize, {
    Vector2? from,
  }) {
    final ow = math.max(objSize.x * 0.74, 22.0);
    final oh = math.max(objSize.y * 0.74, 22.0);

    bool overlapsAt(Vector2 p) {
      final obj = Rect.fromCenter(
        center: Offset(p.x, p.y),
        width: ow,
        height: oh,
      );
      return obj.overlaps(hurtBox);
    }

    if (overlapsAt(objPos)) return true;
    if (from == null) return false;

    const n = 24;
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final p = Vector2(
        from.x + (objPos.x - from.x) * t,
        from.y + (objPos.y - from.y) * t,
      );
      if (overlapsAt(p)) return true;
    }
    return false;
  }

  bool isHitByGroundHazard(Vector2 objPos, Vector2 objSize) {
    final half = math.max(objSize.x, 36) * 0.5;
    final obj = Rect.fromCenter(
      center: Offset(objPos.x, position.y - 2),
      width: half * 2,
      height: 24,
    );
    return obj.overlaps(hurtBox);
  }

  double get runPhase => _runT;

  bool get isFootPlant {
    final half = GameConfig.runCycleSeconds * 0.5;
    final phase = (_runT % half) / half;
    return phase < 0.14 || phase > 0.86;
  }

  @override
  Future<void> onLoad() async {
    priority = 15;
    anchor = Anchor.bottomCenter;
    angle = 0;
    position = Vector2(GameConfig.minerX, GameConfig.groundY);
    final frames = assets.runFrames;
    final scale = assets.runFrameScale(frames.first);
    size = frames.first.srcSize * scale;
    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: assets.runStepSeconds,
      loop: true,
    );
    paint.filterQuality = FilterQuality.high;
  }

  @override
  void render(Canvas canvas) {
    // Soft contact just above soles (local bottom = size.y).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5 - 2, size.y - 1.5),
        width: size.x * 0.52,
        height: 11,
      ),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    super.render(canvas);

    // Feet pivot in local space = bottomCenter = (size.x/2, size.y).
    if (GameConfig.debugGround) {
      canvas.drawCircle(
        Offset(size.x * 0.5, size.y),
        6,
        Paint()
          ..color = const Color(0xFF00E676)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void layout(double screenW, double screenH) {
    _lockFeet();
    _ensureBodySize();
  }
}
