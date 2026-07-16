import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/ambient_life_component.dart';
import 'components/effects/juice_effects.dart';
import 'components/falling_object.dart';
import 'components/ground_debug_component.dart';
import 'components/miner_component.dart';
import 'components/swipe_trail_component.dart';
import 'components/world_background.dart';
import 'core/fill_resolution_viewport.dart';
import 'core/game_config.dart';
import 'effects/juice_spawner.dart';
import 'managers/asset_manager.dart';
import 'managers/audio_manager.dart';
import 'managers/difficulty_manager.dart';
import 'managers/event_manager.dart';
import 'managers/score_manager.dart';
import 'managers/spawner_manager.dart';
import 'models/biome_kind.dart';
import 'models/game_event.dart';
import 'models/object_kind.dart';
import 'systems/camera_shake.dart';
import 'systems/slice_system.dart';

/// Endless run: TAP threats by default; crystal unlocks 5s swipe-SLICE.
class MineRunnerGame extends FlameGame with PanDetector {
  MineRunnerGame()
      : super(
          camera: CameraComponent(
            viewport: FillResolutionViewport(
              resolution: Vector2(
                GameConfig.worldWidth,
                GameConfig.worldHeight,
              ),
            ),
          ),
        ) {
    _rng = math.Random();
    difficulty = DifficultyManager();
    biomeManager = BiomeManager(difficulty);
    events = EventManager(_rng);
    bosses = BossManager(_rng);
    _spawner = SpawnerManager(_rng, difficulty, events, bosses);
    // World (0,0) = top-left of the fixed virtual frame.
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
  }

  late final math.Random _rng;
  final AssetManager assetManager = AssetManager.instance;
  late final DifficultyManager difficulty;
  late final BiomeManager biomeManager;
  late final EventManager events;
  late final BossManager bosses;
  late final SpawnerManager _spawner;
  final ScoreManager scores = ScoreManager();
  final SliceSystem sliceSystem = SliceSystem();
  final CameraShake shake = CameraShake();

  late MinerComponent miner;
  late WorldBackground mineBackground;

  final ValueNotifier<int> meters = ValueNotifier(0);
  final ValueNotifier<bool> running = ValueNotifier(false);
  final ValueNotifier<bool> pauseMenu = ValueNotifier(false);
  final ValueNotifier<String> biomeLabel = ValueNotifier('Classic Mine');
  final ValueNotifier<GameEventKind?> eventBanner = ValueNotifier(null);
  final ValueNotifier<double> sliceModeNotifier = ValueNotifier(0);

  bool isGameOver = false;
  bool _loaded = false;
  double _hitFreeze = 0;
  double _deathFreeze = 0;
  double _eventBannerT = 0;
  double _sliceModeT = 0;

  Offset? _pointerStart;
  bool _pointerMoved = false;

  final List<FallingObject> _objectBuffer = [];
  final Vector2 _headScratch = Vector2.zero();

  static const _hitFreezeDuration = 0.04;

  bool get sliceModeActive => _sliceModeT > 0;

  /// Fixed ground line — never depends on window / BG pixels.
  double get groundY => GameConfig.groundY;

  Iterable<T> _ofType<T extends Component>() => world.children.whereType<T>();

  @override
  Color backgroundColor() => const Color(0xFF0D0A08);

  @override
  Future<void> onLoad() async {
    if (!assetManager.isReady) {
      await assetManager.loadAll();
    }
    await scores.loadPersisted();
    mineBackground = WorldBackground(
      assets: assetManager,
      biomeManager: biomeManager,
      difficulty: difficulty,
    );
    miner = MinerComponent(assets: assetManager);
    await world.add(mineBackground);
    await world.add(miner);
    await world.add(AmbientLifeComponent(rng: _rng));
    await world.add(SwipeTrailComponent(sliceSystem: sliceSystem));
    await world.add(GroundDebugComponent());
    miner.layout(GameConfig.worldWidth, GameConfig.worldHeight);
    _loaded = true;
    overlays.add(GameConfig.overlayTitle);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Fixed world — resize only letterboxes. Miner Y never changes.
    if (!_loaded) return;
    miner.layout(GameConfig.worldWidth, GameConfig.worldHeight);
  }

  void startRun() {
    if (!_loaded) return;
    _clearObjects();
    _clearEffects();
    difficulty.distanceMeters = 0;
    difficulty.runTime = 0;
    scores.resetRun();
    _spawner.reset();
    events.reset();
    bosses.reset();
    biomeManager.reset();
    _hitFreeze = 0;
    _deathFreeze = 0;
    _eventBannerT = 0;
    _sliceModeT = 0;
    sliceModeNotifier.value = 0;
    eventBanner.value = null;
    isGameOver = false;
    pauseMenu.value = false;
    running.value = true;
    overlays.remove(GameConfig.overlayTitle);
    overlays.remove(GameConfig.overlayGameOver);
    overlays.remove(GameConfig.overlayPause);
    overlays.remove(GameConfig.overlayEvent);
    overlays.add(GameConfig.overlayHud);
    shake.runBobEnabled = true;
    resumeEngine();
  }

  void activateSliceMode([double seconds = GameConfig.sliceModeDuration]) {
    _sliceModeT = seconds;
    sliceModeNotifier.value = seconds;
    AudioManager.combo();
    shake.bump(8, duration: 0.15);
  }

  void togglePause() {
    if (!running.value || isGameOver) return;
    pauseMenu.value = !pauseMenu.value;
    if (pauseMenu.value) {
      pauseEngine();
      overlays.add(GameConfig.overlayPause);
    } else {
      overlays.remove(GameConfig.overlayPause);
      resumeEngine();
    }
  }

  void restart() => startRun();

  @override
  void update(double dt) {
    shake.runBobEnabled = running.value && !isGameOver && !pauseMenu.value;
    shake.update(
      dt,
      bobAmpX: GameConfig.runBobAmpX,
      bobAmpY: GameConfig.runBobAmpY,
      bobPeriod: GameConfig.runBobPeriod,
    );
    sliceSystem.tickFade(dt);

    if (_deathFreeze > 0) {
      _deathFreeze -= dt;
      if (_deathFreeze <= 0) _finishGameOver();
      return;
    }

    if (_hitFreeze > 0) {
      _hitFreeze -= dt;
      if (miner.isMounted) {
        miner.layout(GameConfig.worldWidth, GameConfig.worldHeight);
        miner.scale.setValues(1, 1);
      }
      return;
    }

    super.update(dt);

    if (!running.value || isGameOver || pauseMenu.value) return;

    if (_sliceModeT > 0) {
      _sliceModeT -= dt;
      if (_sliceModeT <= 0) {
        _sliceModeT = 0;
        sliceSystem.end();
      }
      sliceModeNotifier.value = _sliceModeT;
    }

    difficulty.tick(dt);
    scores.tick(dt);
    meters.value = difficulty.distanceMeters.round();
    biomeLabel.value = biomeManager.current.label;

    events.tick(dt, _onEventStarted);
    final live = _ofType<FallingObject>()
        .where((o) => o.countsTowardSpawnCap)
        .toList();
    final liveThreats = live.length;
    _spawner.tick(
      dt,
      _spawnObject,
      liveThreats: liveThreats,
    );

    if (_eventBannerT > 0) {
      _eventBannerT -= dt;
      if (_eventBannerT <= 0) {
        eventBanner.value = null;
        overlays.remove(GameConfig.overlayEvent);
      }
    }

    _headScratch.setFrom(miner.position);
    _headScratch.add(miner.headCenter);
    _objectBuffer.clear();
    for (final obj in _ofType<FallingObject>()) {
      _objectBuffer.add(obj);
    }
    for (final obj in _objectBuffer) {
      obj.checkMinerCollision(_headScratch, miner.headRadius);
    }
  }

  void _onEventStarted(GameEventKind kind) {
    eventBanner.value = kind;
    _eventBannerT = 2.6;
    overlays.add(GameConfig.overlayEvent);
    shake.bump(6, duration: 0.15);
  }

  @override
  void render(Canvas canvas) {
    if (shake.offset != Offset.zero) {
      canvas.save();
      canvas.translate(shake.offset.dx, shake.offset.dy);
    }
    super.render(canvas);
    if (shake.offset != Offset.zero) canvas.restore();
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (!running.value || isGameOver || pauseMenu.value) return;
    final world = camera.globalToLocal(info.eventPosition.global);
    final p = Offset(world.x, world.y);
    _pointerStart = p;
    _pointerMoved = false;
    if (sliceModeActive) {
      sliceSystem.begin(p);
    } else {
      _hitFallingAt(p);
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!running.value || isGameOver || pauseMenu.value) return;
    final world = camera.globalToLocal(info.eventPosition.global);
    final p = Offset(world.x, world.y);
    final start = _pointerStart;
    if (start != null && (p - start).distance > GameConfig.tapMaxMove) {
      _pointerMoved = true;
    }

    if (sliceModeActive) {
      sliceSystem.add(p);
      _processSlice();
    } else {
      _hitFallingAt(p);
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (sliceModeActive) {
      sliceSystem.end();
    } else if (!_pointerMoved && _pointerStart != null) {
      _hitFallingAt(_pointerStart!);
    }
    _pointerStart = null;
    _pointerMoved = false;
  }

  @override
  void onPanCancel() {
    sliceSystem.end();
    _pointerStart = null;
    _pointerMoved = false;
  }

  /// World-space tap: any interactable faller under the finger (full sky).
  void _hitFallingAt(Offset worldPos) {
    FallingObject? best;
    var bestDist = double.infinity;
    final finger = Vector2(worldPos.dx, worldPos.dy);
    for (final obj in _ofType<FallingObject>()) {
      if (!obj.canInteract) continue;
      final d = obj.position.distanceTo(finger);
      final reach =
          obj.hitRadius * GameConfig.tapReachMul + GameConfig.tapReachPad;
      if (d <= reach && d < bestDist) {
        bestDist = d;
        best = obj;
      }
    }
    if (best == null) return;
    final perfect = bestDist < best.hitRadius * 0.55;
    best.slice(perfect: perfect);
    AudioManager.slice();
    HapticFeedback.selectionClick();
  }

  void _processSlice() {
    _objectBuffer.clear();
    for (final obj in _ofType<FallingObject>()) {
      if (!obj.canInteract) continue;
      _objectBuffer.add(obj);
    }
    var totalHits = 0;
    for (final obj in _objectBuffer) {
      totalHits += sliceSystem.testSlice(obj);
    }
    if (totalHits > 0) {
      AudioManager.slice();
      HapticFeedback.lightImpact();
    }
  }

  void _spawnObject(ObjectKind kind) {
    final mx = miner.position.x;
    final head = miner.position + miner.headCenter;
    final groundY = GameConfig.groundY;
    final worldW = GameConfig.worldWidth;

    final live = _ofType<FallingObject>()
        .where((o) => o.countsTowardSpawnCap)
        .toList();
    final occupiedXs = live.map((o) => o.position.x).toList();
    final minerLaneBusy = live
            .where((o) => (o.position.x - mx).abs() < worldW * 0.16)
            .length >=
        GameConfig.maxThreatsInMinerLane;

    late final double sx;
    late final double sy;
    if (kind.isGroundHazard) {
      // Spikes ahead on the path — not under the boots.
      sx = mx + worldW * (0.45 + _rng.nextDouble() * 0.38);
      sy = groundY - 1.5;
    } else if (kind.isStalactite) {
      sx = _spawner.spawnX(
        worldW,
        mx,
        occupiedXs: occupiedXs,
        avoidMinerLane: minerLaneBusy,
      );
      sy = _spawner.spawnY(live.length);
    } else {
      sx = _spawner.spawnX(
        worldW,
        mx,
        occupiedXs: occupiedXs,
        avoidMinerLane: minerLaneBusy,
      );
      sy = _spawner.spawnY(live.length);
    }

    final vel = _spawner.velocityFor(
      kind,
      spawnX: sx,
      spawnY: sy,
      headX: head.x,
      headY: head.y,
    );
    final obj = FallingObject(
      kind: kind,
      assets: assetManager,
      vx: vel.vx,
      vy: vel.vy,
      vr: vel.vr,
      onSliced: _onSliced,
      onDamaged: _onDamaged,
      onHitMiner: _onHitMiner,
    );
    obj.position = Vector2(sx, sy);
    world.add(obj);
  }

  void _onDamaged(FallingObject obj, {required bool perfect}) {
    _hitFreeze = _hitFreezeDuration;
    shake.bump(8, duration: 0.12);
    AudioManager.boss();
    JuiceSpawner.onSlice(
      world,
      obj.position,
      obj.kind,
      points: 0,
      perfect: perfect,
      killed: false,
      combo: scores.combo,
    );
  }

  void _onSliced(FallingObject obj, {required bool perfect}) {
    _hitFreeze = _hitFreezeDuration;

    final pts = scores.addSlice(
      obj.kind.baseScore,
      sliceCount: 1,
      perfect: perfect,
    );

    if (obj.kind.isSliceCrystal) {
      activateSliceMode();
      AudioManager.diamond();
      shake.bump(6, duration: 0.12);
    } else {
      switch (obj.kind) {
        case ObjectKind.goldNugget:
          AudioManager.diamond();
          shake.bump(5, duration: 0.1);
        case ObjectKind.dynamite:
          AudioManager.explosion();
          shake.bump(14, duration: 0.22);
        case ObjectKind.bossSpider:
          AudioManager.boss();
          shake.bump(18, duration: 0.28);
        case ObjectKind.spider:
          AudioManager.rock();
          shake.bump(7, duration: 0.12);
        default:
          AudioManager.rock();
          shake.bump(4, duration: 0.1);
      }
    }

    if (scores.combo >= GameConfig.combo3) AudioManager.combo();

    JuiceSpawner.onSlice(
      world,
      obj.position,
      obj.kind,
      points: pts,
      perfect: perfect,
      killed: true,
      combo: scores.combo,
    );
  }

  void _onHitMiner(FallingObject obj) {
    if (isGameOver) return;

    final impact = Vector2(
      (obj.position.x + miner.position.x) * 0.5,
      (obj.position.y + miner.position.y) * 0.5,
    );
    JuiceSpawner.onMinerHit(world, impact, obj.kind);

    isGameOver = true;
    running.value = false;
    scores.breakCombo();
    _sliceModeT = 0;
    sliceModeNotifier.value = 0;
    _deathFreeze = GameConfig.deathFreezeSeconds;
    AudioManager.gameOver();
    shake.bump(16, duration: 0.35);
    HapticFeedback.heavyImpact();
  }

  void _finishGameOver() {
    scores.tryUpdateHighScore();
    overlays.remove(GameConfig.overlayHud);
    overlays.remove(GameConfig.overlayEvent);
    overlays.add(GameConfig.overlayGameOver);
    pauseEngine();
  }

  void _clearObjects() {
    for (final o in _ofType<FallingObject>().toList()) {
      o.removeFromParent();
    }
  }

  void _clearEffects() {
    for (final c in _ofType<ImpactFlash>().toList()) {
      c.removeFromParent();
    }
    for (final c in _ofType<DebrisShard>().toList()) {
      c.removeFromParent();
    }
    for (final c in _ofType<ParticleBurst>().toList()) {
      c.removeFromParent();
    }
    for (final c in _ofType<FloatingPopup>().toList()) {
      c.removeFromParent();
    }
    for (final c in _ofType<GroundSandPuff>().toList()) {
      c.removeFromParent();
    }
  }
}
