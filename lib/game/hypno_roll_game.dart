import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../theme/hypno_colors.dart';
import 'components/fly_ball.dart';
import 'components/guide_passage.dart';
import 'components/hazards.dart';
import 'components/hypno_field.dart';
import 'components/road_renderer.dart';
import 'road_path.dart';
import 'sfx.dart';

/// Side-scrolling flyer: ball races along a road you draw ahead.
class HypnoRollGame extends FlameGame {
  HypnoRollGame() {
    road = RoadPath();
    field = HypnoField();
    ball = FlyBall(road: road);
    roadView = RoadRenderer(road: road, cameraX: () => cameraX);
  }

  late final RoadPath road;
  late final HypnoField field;
  late final FlyBall ball;
  late final RoadRenderer roadView;

  final ValueNotifier<int> meters = ValueNotifier(0);
  final ValueNotifier<int> best = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<int> bestCombo = ValueNotifier(0);
  final ValueNotifier<int> pads = ValueNotifier(1);
  final ValueNotifier<bool> trustMode = ValueNotifier(true);
  final ValueNotifier<bool> playing = ValueNotifier(false);
  final ValueNotifier<int> speedTier = ValueNotifier(0);
  final ValueNotifier<bool> canSave = ValueNotifier(false);
  final ValueNotifier<bool> mirrorActive = ValueNotifier(false);
  final ValueNotifier<String> deathReason = ValueNotifier('');
  /// 0..1 progress inside current 100m segment.
  final ValueNotifier<double> pathProgress = ValueNotifier(0);
  final ValueNotifier<int> pathPassed = ValueNotifier(0);
  final ValueNotifier<int> pathLeft = ValueNotifier(100);

  final _rng = math.Random();

  static const hud = 'hud';
  static const draw = 'draw';
  static const title = 'title';
  static const over = 'over';

  double get cameraX => ball.worldX - size.x * FlyBall.screenXFactor;

  double get aheadSeconds {
    final spd = ball.speed <= 1 ? 1.0 : ball.speed;
    return road.aheadOf(ball.worldX) / spd;
  }

  bool gameOver = false;

  /// Finger is down — keep painting every frame.
  bool isDrawing = false;
  int? activePointer;
  Offset? holdScreen;

  double _spawn = 0;
  double _guideSpawn = 0;
  int _lastTier = 0;
  double _padCooldown = 0;
  double _mirrorTimer = 0;
  String _pendingDeath = '';
  static const int segmentLen = 100;

  @override
  Color backgroundColor() => HypnoColors.voidBg;

  @override
  Future<void> onLoad() async {
    await add(field);
    await add(roadView);
    await add(ball);
    overlays.add(title);
  }

  void start() {
    _clearFx();
    road.clear();
    final y = size.y * 0.62;
    // Short runway ending just ahead of the ball's screen spot
    road.ensureRunway(fromX: -40, toX: size.x * 0.48, y: y, step: 24);
    ball.reset(y);
    pads.value = 1;
    combo.value = 0;
    meters.value = 0;
    speedTier.value = 0;
    canSave.value = false;
    mirrorActive.value = false;
    deathReason.value = '';
    pathProgress.value = 0;
    pathPassed.value = 0;
    pathLeft.value = segmentLen;
    _lastTier = 0;
    _spawn = 2.4; // calm opening like Subway Surfers
    _guideSpawn = 3.2;
    _padCooldown = 0;
    _mirrorTimer = 0;
    isDrawing = false;
    activePointer = null;
    holdScreen = null;
    _pendingDeath = '';
    gameOver = false;
    trustMode.value = true;
    ball.trustMode = true;
    field.intensity = 1;
    roadView.showFake = true;
    playing.value = true;
    overlays.remove(title);
    overlays.remove(over);
    overlays.add(draw, priority: 0); // under HUD — holds stay alive
    overlays.add(hud, priority: 1);
    resumeEngine();
  }

  void restart() => start();

  void toggleMode() {
    if (!playing.value || gameOver) return;
    trustMode.value = !trustMode.value;
    ball.trustMode = trustMode.value;
    field.intensity = trustMode.value ? 1.0 : 1.7;
    ball.applyTier(_lastTier);
    Sfx.toggle();
    add(
      FloatText(
        at: ball.position.clone(),
        text: trustMode.value ? 'TRUST' : 'PANIC',
        color: trustMode.value ? HypnoColors.trust : HypnoColors.panic,
      ),
    );
  }

  void usePad() {
    if (!playing.value || gameOver) return;
    if (pads.value <= 0 || _padCooldown > 0) return;
    if (!canSave.value) return;

    pads.value -= 1;
    _padCooldown = 5.0;
    ball.placePad(road);
    Sfx.pad();
    add(
      FloatText(
        at: ball.position.clone(),
        text: 'SAVED!',
        color: HypnoColors.pad,
      ),
    );
  }

  // —— Live finger stroke (draw where you drag) ——

  double _mirrorY(double screenY) {
    if (!mirrorActive.value) return screenY;
    final mid = size.y * 0.5;
    return mid * 2 - screenY;
  }

  Offset _screenToWorld(Offset screen) {
    return Offset(cameraX + screen.dx, _mirrorY(screen.dy));
  }

  void pointerDown(int pointer, Offset screen) {
    if (!playing.value || gameOver) return;
    activePointer = pointer;
    isDrawing = true;
    holdScreen = screen;
    // Start stroke at finger — no auto-fill
    _strokeTo(screen, start: true);
  }

  void pointerMove(int pointer, Offset screen) {
    if (!isDrawing) return;
    if (activePointer != null && activePointer != pointer) return;
    holdScreen = screen;
    _strokeTo(screen);
  }

  void pointerUp(int pointer) {
    if (activePointer != null && activePointer != pointer) return;
    isDrawing = false;
    activePointer = null;
    holdScreen = null;
  }

  /// Tip follows the finger closely — ball is near finger on screen.
  void _strokeTo(Offset screen, {bool start = false}) {
    var target = _screenToWorld(screen);
    // Soft lead: tip just ahead of ball so it never sits on / behind it
    final minAheadX = ball.worldX + math.max(40.0, ball.speed * 0.28);
    if (target.dx < minAheadX) {
      target = Offset(minAheadX, target.dy);
    }
    target = Offset(target.dx, target.dy.clamp(28.0, size.y - 28.0));

    if (!road.hasPoints) {
      _commit(Offset(ball.worldX + 20, target.dy));
      _commit(target);
      return;
    }

    final last = road.points.last;

    // Holding still near tip: nudge height toward finger, tiny forward crawl
    if (target.dx <= last.dx + 3) {
      if (start || (target.dy - last.dy).abs() > 3) {
        _commit(Offset(math.max(last.dx + 4, minAheadX), target.dy));
      }
      return;
    }

    final delta = target - last;
    final dist = delta.distance;
    final steps = math.max(1, (dist / 6).ceil().clamp(1, 56));
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      _commit(Offset(last.dx + delta.dx * t, last.dy + delta.dy * t));
    }
  }

  /// Keep a short safety cushion ahead of the ball while holding.
  void _maintainRoadBuffer() {
    if (!isDrawing || holdScreen == null || !road.hasPoints) return;
    final y = _screenToWorld(holdScreen!).dy.clamp(28.0, size.y - 28.0);
    final needX = ball.worldX + math.max(48.0, ball.speed * 0.32);
    var tip = road.points.last;
    var guard = 0;
    while (tip.dx < needX && guard++ < 40) {
      final nextX = math.min(tip.dx + 10, needX);
      final nextY = tip.dy + (y - tip.dy) * 0.55;
      _commit(Offset(nextX, nextY));
      tip = road.points.last;
    }
  }

  void _commit(Offset w) {
    final last = road.hasPoints ? road.points.last : null;
    final dist = last == null ? 8.0 : (w - last).distance;
    if (dist < 2.5 && last != null) return;
    road.addWorldPoint(w, force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!playing.value || gameOver) return;

    // Path only extends to the finger — no auto-fill.
    roadView.fingerScreen = isDrawing ? holdScreen : null;
    if (isDrawing && holdScreen != null) {
      _strokeTo(holdScreen!);
      _maintainRoadBuffer();
    }

    if (_padCooldown > 0) _padCooldown -= dt;

    if (_mirrorTimer > 0) {
      _mirrorTimer -= dt;
      if (_mirrorTimer <= 0) {
        mirrorActive.value = false;
        add(
          FloatText(
            at: Vector2(size.x * 0.5, size.y * 0.2),
            text: 'MIRROR OFF',
            color: HypnoColors.uiDim,
          ),
        );
      }
    }

    final crisis = ball.falling || aheadSeconds < 0.4;
    if (crisis != canSave.value) canSave.value = crisis;

    final m = ball.meters.floor();
    if (m != meters.value) meters.value = m;

    final inSeg = m % segmentLen;
    pathPassed.value = inSeg;
    pathLeft.value = segmentLen - inSeg;
    pathProgress.value = inSeg / segmentLen;

    final tier = m ~/ 100;
    if (tier > _lastTier) {
      _lastTier = tier;
      speedTier.value = tier;
      ball.applyTier(tier);
      pads.value = (pads.value + 1).clamp(0, 3);
      Sfx.speedUp();
      add(
        FloatText(
          at: Vector2(size.x * 0.5, size.y * 0.22),
          text: '${tier * 100}m  SPEED UP',
          color: HypnoColors.roadGlow,
        ),
      );
    }

    if (!ball.alive) {
      _fail(_deathFromState());
      return;
    }

    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = _nextSpawnDelay(m);
      _spawnHazard(m);
    }

    _guideSpawn -= dt;
    if (_guideSpawn <= 0) {
      _guideSpawn = _nextGuideDelay(m);
      _spawnGuide(m);
    }
  }

  /// Subway-style ramp: calm start → geometry → hazards → chaos.
  int _phase(int m) {
    if (m < 35) return 0; // intro — almost empty
    if (m < 80) return 1; // draw tutorials / easy rings
    if (m < 160) return 2; // spikes + holes
    if (m < 260) return 3; // fans + harder guides
    return 4; // magnet / mirror chaos
  }

  double _nextSpawnDelay(int m) {
    return switch (_phase(m)) {
      0 => 2.8 + _rng.nextDouble() * 0.8,
      1 => 1.9 + _rng.nextDouble() * 0.5,
      2 => 1.35 + _rng.nextDouble() * 0.35,
      3 => 1.05 + _rng.nextDouble() * 0.25,
      _ => (0.75 + _rng.nextDouble() * 0.25 - _lastTier * 0.03).clamp(0.42, 1.0),
    };
  }

  double _nextGuideDelay(int m) {
    return switch (_phase(m)) {
      0 => 4.5,
      1 => 3.2,
      2 => 2.8,
      3 => 2.4,
      _ => 2.1,
    };
  }

  String _deathFromState() {
    if (_pendingDeath == 'spike') return 'spike';
    if (_pendingDeath == 'magnet') return 'magnet';
    if (ball.falling) return 'gap';
    return 'gap';
  }

  void _spawnHazard(int m) {
    final phase = _phase(m);
    // Early game: mostly rings / gentle skips — ramp like Subway Surfers.
    if (phase == 0) {
      if (_rng.nextDouble() < 0.55) return; // often skip
      _spawnTypedHazard(HazardType.ring);
      return;
    }

    final roll = _rng.nextDouble();
    HazardType? type;
    if (phase == 1) {
      if (roll < 0.70) {
        type = HazardType.ring;
      } else if (roll < 0.92) {
        type = HazardType.spike;
      } else {
        return;
      }
    } else if (phase == 2) {
      if (roll < 0.28) {
        type = HazardType.hole;
      } else if (roll < 0.52) {
        type = HazardType.spike;
      } else if (roll < 0.78) {
        type = HazardType.ring;
      } else if (roll < 0.92) {
        type = HazardType.fan;
      } else {
        return;
      }
    } else if (phase == 3) {
      if (roll < 0.22) {
        type = HazardType.hole;
      } else if (roll < 0.40) {
        type = HazardType.spike;
      } else if (roll < 0.58) {
        type = HazardType.fan;
      } else if (roll < 0.78) {
        type = HazardType.ring;
      } else if (roll < 0.90) {
        type = HazardType.magnet;
      } else {
        _triggerMirror();
        return;
      }
    } else {
      if (roll < 0.18) {
        type = HazardType.hole;
      } else if (roll < 0.34) {
        type = HazardType.spike;
      } else if (roll < 0.50) {
        type = HazardType.fan;
      } else if (roll < 0.66) {
        type = HazardType.ring;
      } else if (roll < 0.84) {
        type = HazardType.magnet;
      } else {
        _triggerMirror();
        return;
      }
    }

    _spawnTypedHazard(type);
  }

  void _spawnTypedHazard(HazardType type) {
    final wx = ball.worldX + size.x * 0.8 + _rng.nextDouble() * 100;
    final hy = road.heightAt(wx) ?? (size.y * 0.62);
    final ay = switch (type) {
      HazardType.ring => hy - 10,
      HazardType.fan => hy - 8,
      HazardType.hole => hy + 6,
      HazardType.spike => hy - 6,
      HazardType.magnet => hy - 4,
    };

    if (type == HazardType.hole) {
      road.points.removeWhere((p) => p.dx > wx - 8 && p.dx < wx + 78);
    }

    final fakeY = hy + (_rng.nextBool() ? -34.0 : 34.0);

    add(
      TrackHazard(
        type: type,
        worldX: wx,
        anchorY: ay,
        fakePullY: fakeY,
        ball: ball,
        cameraX: () => cameraX,
        onHit: () {
          if (type == HazardType.spike) {
            _fail('spike');
          } else if (type == HazardType.magnet) {
            _fail('magnet');
          } else {
            _fail('gap');
          }
        },
        onPerfect: () {
          combo.value += 1;
          if (combo.value > bestCombo.value) bestCombo.value = combo.value;
          final mult = (1 + combo.value ~/ 2).clamp(1, 9);
          Sfx.perfect();
          add(
            FloatText(
              at: ball.position.clone(),
              text: 'PERFECT x$mult',
              color: HypnoColors.ring,
            ),
          );
        },
        onClose: () {
          combo.value += 1;
          if (combo.value > bestCombo.value) bestCombo.value = combo.value;
          Sfx.nearMiss();
          add(
            FloatText(
              at: ball.position.clone(),
              text: 'CLOSE!',
              color: HypnoColors.roadGlow,
            ),
          );
        },
      ),
    );
  }

  void _spawnGuide(int m) {
    final phase = _phase(m);
    final kinds = switch (phase) {
      0 => [PassageKind.wave, PassageKind.arch],
      1 => [PassageKind.wave, PassageKind.arch, PassageKind.ramp],
      2 => [
          PassageKind.arch,
          PassageKind.zigzag,
          PassageKind.wave,
          PassageKind.ramp,
        ],
      3 => [
          PassageKind.zigzag,
          PassageKind.snake,
          PassageKind.arch,
          PassageKind.wave,
        ],
      _ => PassageKind.values.toList(),
    };
    final kind = kinds[_rng.nextInt(kinds.length)];
    final startX = ball.worldX + size.x * 0.72 + _rng.nextDouble() * 40;
    final baseY = road.heightAt(startX) ?? (size.y * 0.62);
    final pts = GuidePassage.build(
      kind: kind,
      startX: startX,
      baseY: baseY,
      rng: _rng,
    );

    // Hole under arch — force drawing over the gap
    if (kind == PassageKind.arch || kind == PassageKind.ramp) {
      final mid = pts[pts.length ~/ 2].dx;
      road.points.removeWhere((p) => p.dx > mid - 36 && p.dx < mid + 50);
    }

    add(
      GuidePassage(
        kind: kind,
        points: pts,
        ball: ball,
        cameraX: () => cameraX,
        label: GuidePassage.titleOf(kind),
        onTraced: ({required bool perfect}) {
          if (perfect) {
            combo.value += 2;
            if (combo.value > bestCombo.value) bestCombo.value = combo.value;
            Sfx.perfect();
            add(
              FloatText(
                at: ball.position.clone(),
                text: 'GEO PERFECT',
                color: HypnoColors.ring,
              ),
            );
            add(BurstFx(at: ball.position.clone(), color: HypnoColors.ring));
          } else {
            combo.value += 1;
            if (combo.value > bestCombo.value) bestCombo.value = combo.value;
            Sfx.nearMiss();
            add(
              FloatText(
                at: ball.position.clone(),
                text: 'GEO OK',
                color: HypnoColors.roadGlow,
              ),
            );
          }
        },
      ),
    );
  }

  void _triggerMirror() {
    _mirrorTimer = 2.2;
    mirrorActive.value = true;
    Sfx.toggle();
    add(
      FloatText(
        at: Vector2(size.x * 0.5, size.y * 0.2),
        text: 'MIRROR 2s',
        color: HypnoColors.fake,
      ),
    );
  }

  void _fail(String reason) {
    if (gameOver) return;
    gameOver = true;
    ball.alive = false;
    isDrawing = false;
    activePointer = null;
    holdScreen = null;

    deathReason.value = switch (reason) {
      'spike' => 'Врезался в шип',
      'magnet' => 'Повёлся на фейк-линию',
      'gap' => 'Дорога оборвалась — не успел дорисовать',
      _ => 'Сорвался с пути',
    };

    if (combo.value > bestCombo.value) bestCombo.value = combo.value;
    combo.value = 0;

    Sfx.die();
    add(BurstFx(at: ball.position.clone(), color: HypnoColors.hazard));
    if (meters.value > best.value) best.value = meters.value;
    overlays.remove(draw);
    overlays.remove(hud);
    overlays.add(over);
    Future<void>.delayed(const Duration(milliseconds: 280), pauseEngine);
  }

  void _clearFx() {
    children.whereType<TrackHazard>().toList().forEach((e) => e.removeFromParent());
    children.whereType<GuidePassage>().toList().forEach((e) => e.removeFromParent());
    children.whereType<FloatText>().toList().forEach((e) => e.removeFromParent());
    children.whereType<BurstFx>().toList().forEach((e) => e.removeFromParent());
  }
}
