import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/game_config.dart';
import '../effects/juice_spawner.dart';
import '../managers/asset_manager.dart';
import '../mine_runner_game.dart';
import '../models/object_kind.dart';

typedef ObjectSliced = void Function(FallingObject obj, {required bool perfect});
typedef ObjectHitMiner = void Function(FallingObject obj);

/// Falling mine object — rocks, spiders, bonuses, hazards.
class FallingObject extends PositionComponent
    with HasGameReference<MineRunnerGame> {
  FallingObject({
    required this.kind,
    required this.assets,
    required this.vx,
    required this.vy,
    required this.vr,
    required this.onSliced,
    required this.onHitMiner,
    this.onDamaged,
  }) {
    // Size ready immediately — never fly with 0×0 hurtbox before onLoad.
    size = Vector2(kind.targetHeight, kind.targetHeight);
    anchor = kind.isGroundHazard ? Anchor.bottomCenter : Anchor.center;
  }

  final ObjectKind kind;
  final AssetManager assets;
  final ObjectSliced onSliced;
  final ObjectHitMiner onHitMiner;
  final void Function(FallingObject h, {required bool perfect})? onDamaged;

  double vx;
  double vy;
  double vr;
  int hp = 1;
  bool dead = false;
  bool _dying = false;
  bool _cracked = false;
  bool _landed = false;
  double _deathT = 0;
  double _scale = 1;
  double _renderAlpha = 1;
  double _wobbleT = 0;
  double _wobbleAmp = 0;
  Sprite? _sprite;
  final Vector2 _prevPos = Vector2.zero();
  bool _hasPrev = false;

  @override
  Future<void> onLoad() async {
    priority = kind.isGroundHazard ? 12 : 8;
    hp = kind.maxHp;
    // Spikes sit on the road — pivot at soles so Y = ground is exact.
    anchor = kind.isGroundHazard ? Anchor.bottomCenter : Anchor.center;
    _wobbleAmp = 2.5 + math.Random().nextDouble() * 4.5;
    _wobbleT = math.Random().nextDouble() * math.pi * 2;
    _sprite = assets.spriteFor(kind);
    if (_sprite != null) {
      _scale = assets.normalizedScale(kind, _sprite!);
      size = _sprite!.srcSize * _scale;
    } else if (kind.isGroundHazard) {
      // Wide enough to read on the cobbles.
      size = Vector2(78, 44);
      _scale = 1;
    } else {
      size = Vector2(kind.targetHeight, kind.targetHeight);
      _scale = 1;
    }
  }

  /// Hurt box size — never collapses while sprite is loading.
  Vector2 get hurtSize {
    final w = size.x > 8 ? size.x : kind.targetHeight;
    final h = size.y > 8 ? size.y : kind.targetHeight;
    return Vector2(w, h);
  }

  double get hitRadius => size.length * 0.38;

  bool get isDangerous => kind.isDangerous && !_dying;

  bool get canInteract => !dead && !_dying && !_landed;

  /// Counts for spawn cap even while death juice plays (avoids 4-visible dumps).
  bool get countsTowardSpawnCap =>
      kind.isDangerous && !dead && !_landed;

  bool get _isRock =>
      kind == ObjectKind.rockSmall ||
      kind == ObjectKind.rockMedium ||
      kind == ObjectKind.rockLarge ||
      kind == ObjectKind.debris;

  double get floorContactY => position.y + math.max(size.y, 24) * 0.5;

  bool touchesFloor(double groundY) => floorContactY >= groundY;

  void snapToFloor(double groundY) {
    final h = math.max(size.y, 24);
    position.y = groundY - h * 0.5;
    vy = 0;
    vx *= 0.2;
  }

  void clampAboveFloor(double groundY) {
    if (floorContactY > groundY) snapToFloor(groundY);
  }

  void _landOnPath(double groundY) {
    if (_landed || dead) return;
    _landed = true;
    dead = true;
    snapToFloor(groundY);
    JuiceSpawner.onGroundHit(game.world, Vector2(position.x, groundY), kind);
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final groundY = GameConfig.groundY;

    if (_dying) {
      _deathT += dt;
      vr += 14 * dt;
      _scale = math.max(0.05, _scale * (1 - dt * 3.5));
      _renderAlpha = math.max(0, 1 - _deathT / 0.55);
      angle += vr * dt;
      position.y += vy * dt * 0.35;
      vy += 160 * dt;
      clampAboveFloor(groundY);
      if (_deathT >= 0.55) removeFromParent();
      return;
    }

    if (dead || _landed) return;

    _prevPos.setFrom(position);
    _hasPrev = true;

    // —— Path spikes: glued to cobblestone top, scroll with the road ——
    if (kind.isGroundHazard) {
      final scroll = game.difficulty.bgScrollSpeed;
      position.x += -scroll * 1.05 * dt;
      // bottomCenter → spike base locked to path surface every frame.
      position.y = groundY - 1.5;
      angle = 0;
      _checkHitMinerAfterMove();
      if (position.x < -80) removeFromParent();
      return;
    }

    _wobbleT += dt * 5.5;
    final wobble = kind.isStalactite ? 0.0 : _wobbleAmp;
    position.x += vx * dt + math.sin(_wobbleT) * wobble * dt;
    position.y += vy * dt;
    angle += vr * dt;

    final grav = kind.isStalactite
        ? 140.0
        : (_isRock ? 95.0 : 70.0);
    vy += grav * dt;
    if (_isRock) vr *= 1 + dt * 0.15;

    // Hit test right after move — so through-the-skull can't skip a frame.
    if (_checkHitMinerAfterMove()) return;

    // Missed fallers → smash onto the path.
    if (touchesFloor(groundY) || position.y > GameConfig.worldHeight + 20) {
      // If we reach the path while still in the miner column, we flew through him.
      if (_checkHitMinerAfterMove()) return;
      if (_inMinerKillColumn(from: _hasPrev ? _prevPos : null)) {
        dead = true;
        onHitMiner(this);
        removeFromParent();
        return;
      }
      _landOnPath(groundY);
    }
  }

  /// Wide padded hull around the whole dwarf (hat+pack+belly+boots).
  bool _inMinerKillColumn({Vector2? from}) {
    if (!kind.isDangerous || !game.miner.isMounted) return false;
    return game.miner.isHitBy(
      position,
      hurtSize,
      from: from,
    );
  }

  bool _checkHitMinerAfterMove() {
    if (dead || _dying || _landed || !isDangerous) return false;
    if (!game.miner.isMounted) return false;

    final pos = position;
    final prev = _hasPrev ? _prevPos : null;

    // 1) Nuclear column first (hat / pack / belly / legs).
    if (_inMinerKillColumn(from: prev)) {
      dead = true;
      onHitMiner(this);
      removeFromParent();
      return true;
    }

    // 2) Detailed zones as backup.
    final hit = kind.isGroundHazard
        ? game.miner.isHitByGroundHazard(pos, hurtSize)
        : game.miner.isHitBy(pos, hurtSize, from: prev);
    if (!hit) return false;

    dead = true;
    onHitMiner(this);
    removeFromParent();
    return true;
  }

  void slice({required bool perfect}) {
    if (dead || _dying || _landed) return;
    hp -= 1;
    if (hp <= 0) {
      _dying = true;
      _deathT = 0;
      vr = (_cracked ? 6.0 : 10.0) * (hp.isEven ? 1 : -1);
      onSliced(this, perfect: perfect);
    } else {
      _cracked = true;
      _scale *= 0.9;
      vr *= 1.35;
      onDamaged?.call(this, perfect: perfect);
    }
  }

  void checkMinerCollision(Vector2 minerHead, double headR) {
    if (dead || _dying || _landed || !isDangerous) return;
    if (!game.miner.isMounted) return;

    final prev = _hasPrev ? _prevPos : null;
    if (_inMinerKillColumn(from: prev)) {
      dead = true;
      onHitMiner(this);
      removeFromParent();
      return;
    }

    final pos = position;
    final hit = kind.isGroundHazard
        ? game.miner.isHitByGroundHazard(pos, hurtSize)
        : game.miner.isHitBy(pos, hurtSize, from: prev);
    if (!hit) return;

    dead = true;
    onHitMiner(this);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (dead || _landed) return;

    if (!kind.isGroundHazard) {
      final shadowScale = (1 + position.y / 900).clamp(0.6, 1.8);
      canvas.save();
      canvas.translate(0, size.y * 0.42);
      canvas.scale(1.0, 0.35);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.x * 0.7 * shadowScale,
          height: size.y * 0.55,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28 * _renderAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.restore();
    }

    canvas.save();
    if (_dying) canvas.scale(_scale);
    canvas.rotate(angle);

    if (_sprite != null) {
      final paint = Paint()..color = Colors.white.withValues(alpha: _renderAlpha);
      if (_cracked || (hp < kind.maxHp && !_dying)) {
        paint.colorFilter = const ColorFilter.mode(
          Color(0xFFFF8A80),
          BlendMode.modulate,
        );
      }
      _sprite!.render(
        canvas,
        size: size,
        anchor: Anchor.center,
        overridePaint: paint,
      );

      if (kind == ObjectKind.bossSpider) {
        _drawBossEyes(canvas);
      }
      if (_cracked && kind == ObjectKind.bossSpider) {
        _drawCrack(canvas);
      }
    } else if (kind.isGroundHazard) {
      // Draw with soles at local y=0 (matches bottomCenter anchor).
      final s = size.y / 36.0;
      assets.drawProcedural(canvas, kind, s);
    } else {
      canvas.scale(_dying ? 1 : _scale);
      assets.drawProcedural(canvas, kind, 1);
    }

    canvas.restore();
  }

  void _drawBossEyes(Canvas canvas) {
    final eyeY = -size.y * 0.1;
    final eyeX = size.x * 0.16;
    final glow = _cracked ? 8.0 : 5.0;
    for (final ex in [-eyeX, eyeX]) {
      canvas.drawCircle(
        Offset(ex, eyeY),
        glow,
        Paint()
          ..color =
              const Color(0xFFFF1744).withValues(alpha: _cracked ? 0.9 : 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(ex, eyeY),
        3.5,
        Paint()..color = const Color(0xFFFF5252),
      );
      canvas.drawCircle(
        Offset(ex + 0.8, eyeY - 0.8),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  void _drawCrack(Canvas canvas) {
    final crack = Paint()
      ..color = const Color(0xFF212121).withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-size.x * 0.15, -size.y * 0.05),
      Offset(size.x * 0.2, size.y * 0.15),
      crack,
    );
    canvas.drawLine(
      Offset(size.x * 0.05, -size.y * 0.2),
      Offset(-size.x * 0.1, size.y * 0.1),
      crack,
    );
  }
}
