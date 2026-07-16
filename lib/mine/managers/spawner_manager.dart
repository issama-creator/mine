import 'dart:math' as math;

import '../core/game_config.dart';
import '../managers/difficulty_manager.dart';
import '../managers/event_manager.dart';
import '../models/biome_kind.dart';
import '../models/game_event.dart';
import '../models/object_kind.dart';

enum _LineMode { none, horizontal, vertical, diagonal }

class _QueuedSpawn {
  _QueuedSpawn(
    this.kind,
    this.wait, {
    this.spreadIndex = 0,
    this.spreadTotal = 1,
    this.lineMode = _LineMode.none,
    this.lineCenterX,
  });

  final ObjectKind kind;
  double wait;
  final int spreadIndex;
  final int spreadTotal;
  final _LineMode lineMode;
  final double? lineCenterX;
}

class SpawnerManager {
  SpawnerManager(this._rng, this._difficulty, this._events, this._bosses);

  final math.Random _rng;
  final DifficultyManager _difficulty;
  final EventManager _events;
  final BossManager _bosses;

  double _timer = 1.0;
  double _sinceLastSpawn = 99;
  int _rockfallBurst = 0;
  final List<_QueuedSpawn> _queue = [];

  /// Last chosen spawn X — helps keep consecutive rains apart.
  double _lastSpawnX = -999;

  /// Fan / cluster lane spread for the next spawn callback.
  int _patternIdx = 0;
  int _patternCount = 1;
  _LineMode _lineMode = _LineMode.none;
  double? _lineCenterX;

  /// Last rock size — keeps consecutive falls visually similar.
  ObjectKind? _lastRockKind;
  bool _lastWasObjekt = false;

  void reset() {
    _timer = 1.2;
    _sinceLastSpawn = 99;
    _rockfallBurst = 0;
    _lastSpawnX = -999;
    _queue.clear();
    _patternIdx = 0;
    _patternCount = 1;
    _lineMode = _LineMode.none;
    _lineCenterX = null;
    _lastRockKind = null;
    _lastWasObjekt = false;
  }

  int get patternSpreadIndex => _patternIdx;
  int get patternSpreadCount => _patternCount;

  void _doSpawn(void Function(ObjectKind kind) spawn, ObjectKind kind) {
    spawn(kind);
    _sinceLastSpawn = 0;
    _patternIdx = 0;
    _patternCount = 1;
    _lineMode = _LineMode.none;
    _lineCenterX = null;
    _noteSpawnKind(kind);
  }

  void _noteSpawnKind(ObjectKind kind) {
    if (kind == ObjectKind.rockSmall ||
        kind == ObjectKind.rockMedium ||
        kind == ObjectKind.rockLarge) {
      _lastRockKind = kind;
    }
    _lastWasObjekt = kind.isObjekt;
  }

  void _enqueue(
    ObjectKind kind,
    double wait, {
    int spreadIndex = 0,
    int spreadTotal = 1,
    _LineMode lineMode = _LineMode.none,
    double? lineCenterX,
  }) {
    _queue.add(
      _QueuedSpawn(
        kind,
        wait,
        spreadIndex: spreadIndex,
        spreadTotal: spreadTotal,
        lineMode: lineMode,
        lineCenterX: lineCenterX,
      ),
    );
  }

  /// Mine ceiling ahead — cluster over the tunnel in front of the miner.
  void _enqueueHorizontalLine() {
    final center = _aheadCenterX();
    final kind = _pickLineKind();
    final gap = 0.52 + _rng.nextDouble() * 0.16;
    for (var i = 0; i < 3; i++) {
      _enqueue(
        kind,
        i * gap,
        spreadIndex: i,
        spreadTotal: 3,
        lineMode: _LineMode.horizontal,
        lineCenterX: center,
      );
    }
  }

  /// Stalactite train — same column, stacked deep, falls in sequence.
  void _enqueueVerticalTrain() {
    final x = _aheadCenterX();
    final kind = _rng.nextDouble() < 0.75 ? _rockWeighted() : _pickLineKind();
    final gap = 0.58 + _rng.nextDouble() * 0.14;
    for (var i = 0; i < 3; i++) {
      _enqueue(
        kind,
        i * gap,
        spreadIndex: i,
        spreadTotal: 3,
        lineMode: _LineMode.vertical,
        lineCenterX: x,
      );
    }
  }

  /// Diagonal telegraph — top-left → bottom-right wave.
  void _enqueueDiagonalLine() {
    final anchorX = _aheadCenterX();
    final kind = _pickLineKind();
    final gap = 0.46 + _rng.nextDouble() * 0.12;
    for (var i = 0; i < 3; i++) {
      _enqueue(
        kind,
        i * gap,
        spreadIndex: i,
        spreadTotal: 3,
        lineMode: _LineMode.diagonal,
        lineCenterX: anchorX,
      );
    }
  }

  ObjectKind _pickLineKind() {
    final r = _rng.nextDouble();
    if (r < 0.62) return _rockWeighted();
    if (r < 0.82) return _pickObjekt();
    return _pickKind(null);
  }

  /// Runner-style bundles: singles, sky lines, trains, pairs.
  void _enqueuePattern(GameEventKind? event) {
    if (event != null) {
      _enqueue(_pickKind(event), 0);
      return;
    }

    final m = _difficulty.distanceMeters;
    if (m < 40) {
      _enqueue(_pickKind(null), 0);
      return;
    }

    final roll = _rng.nextDouble();
    if (roll < 0.38) {
      _enqueue(_pickKind(null), 0);
    } else if (roll < 0.58) {
      _enqueueHorizontalLine();
    } else if (roll < 0.72) {
      _enqueueVerticalTrain();
    } else if (roll < 0.82) {
      _enqueueDiagonalLine();
    } else if (roll < 0.91) {
      final k = _pickKind(null);
      _enqueue(k, 0, spreadIndex: 0, spreadTotal: 2);
      _enqueue(k, 0.55 + _rng.nextDouble() * 0.15, spreadIndex: 1, spreadTotal: 2);
    } else {
      for (var i = 0; i < 2; i++) {
        _enqueue(
          _pickLineKind(),
          i * 0.42,
          spreadIndex: i,
          spreadTotal: 2,
        );
      }
    }
  }

  bool _drainQueue(
    void Function(ObjectKind kind) spawn, {
    required int liveThreats,
  }) {
    if (_queue.isEmpty) return false;

    var spawned = false;
    var threats = liveThreats;
    while (_queue.isNotEmpty && _queue.first.wait <= 0) {
      if (threats >= GameConfig.maxLiveThreats) break;
      if (_sinceLastSpawn < GameConfig.minSpawnGap * 0.9) break;

      final item = _queue.removeAt(0);
      _patternIdx = item.spreadIndex;
      _patternCount = item.spreadTotal;
      _lineMode = item.lineMode;
      _lineCenterX = item.lineCenterX;
      spawn(item.kind);
      _sinceLastSpawn = 0;
      _noteSpawnKind(item.kind);
      spawned = true;
      threats += 1;
    }
    return spawned;
  }

  /// Fair rain: max 3, spaced in time + lanes — never a 4-wall on the head.
  void tick(
    double dt,
    void Function(ObjectKind kind) spawn, {
    int liveThreats = 0,
  }) {
    _bosses.tick(_difficulty.distanceMeters);
    _sinceLastSpawn += dt;

    for (final item in _queue) {
      item.wait -= dt;
    }

    if (_queue.isNotEmpty) {
      _drainQueue(spawn, liveThreats: liveThreats);
      return;
    }

    if (liveThreats >= GameConfig.maxLiveThreats) {
      _timer = math.max(_timer, 0.2);
      return;
    }

    if (_sinceLastSpawn < GameConfig.minSpawnGap) {
      return;
    }

    _timer -= dt;

    if (_bosses.consumeBossSpawn(_difficulty.distanceMeters)) {
      if (liveThreats <= GameConfig.maxLiveThreats - 1) {
        _doSpawn(spawn, ObjectKind.bossSpider);
        _timer = GameConfig.minSpawnGap * 1.4;
      }
      return;
    }

    if (_timer > 0) return;

    final event = _events.current;
    final gap = math.max(
      GameConfig.minSpawnGap,
      _intervalFor(event) * (1.0 + _rng.nextDouble() * 0.25),
    );
    _timer = gap;

    // Rockfall: one rock at a time only (no burst dump).
    if (event == GameEventKind.rockfall) {
      if (_rockfallBurst <= 0) {
        _rockfallBurst = 2 + _rng.nextInt(2); // 2–3 total, heavily spaced
      }
      _rockfallBurst--;
      _doSpawn(spawn, _rockWeighted());
      _timer = math.max(_timer, GameConfig.minSpawnGap * 1.15);
      return;
    }
    _rockfallBurst = 0;

    _enqueuePattern(event);
    _drainQueue(spawn, liveThreats: liveThreats);
  }

  double _intervalFor(GameEventKind? event) {
    final base = _difficulty.spawnInterval;
    if (event == null) return base;
    return switch (event) {
      GameEventKind.crystalRain => base * 0.95,
      GameEventKind.spiderNest => base * 0.92,
      GameEventKind.treasureRush => base * 0.95,
      GameEventKind.dynamiteZone => base * 0.95,
      GameEventKind.rockfall => base * 1.0,
    };
  }

  ObjectKind _pickObjekt() {
    final r = _rng.nextDouble();
    if (r < 0.24) return ObjectKind.objCrate;
    if (r < 0.36) return ObjectKind.objCrystal;
    if (r < 0.50) return ObjectKind.objDynamite;
    if (r < 0.72) return ObjectKind.objSaw;
    return ObjectKind.objSpikeBlock;
  }

  ObjectKind _pickKind(GameEventKind? event) {
    final m = _difficulty.distanceMeters;
    final biome = _difficulty.biome;

    if (event != null) {
      return switch (event) {
        GameEventKind.crystalRain => _rng.nextDouble() < 0.55
            ? ObjectKind.objCrystal
            : (_rng.nextDouble() < 0.65 ? ObjectKind.diamond : ObjectKind.goldNugget),
        GameEventKind.spiderNest => ObjectKind.spider,
        GameEventKind.treasureRush => _rng.nextDouble() < 0.45
            ? ObjectKind.objCrystal
            : (_rng.nextDouble() < 0.5 ? ObjectKind.diamond : ObjectKind.goldNugget),
        GameEventKind.dynamiteZone =>
          _rng.nextDouble() < 0.65 ? ObjectKind.objDynamite : ObjectKind.dynamite,
        GameEventKind.rockfall => _rockWeighted(),
      };
    }

    // Objekts mix in gently — avoid rock ↔ crate whiplash.
    if (m >= 25) {
      var objChance = 0.22;
      if (_lastWasObjekt) objChance = 0.38;
      if (_rng.nextDouble() < objChance) return _pickObjekt();
    }

    final roll = _rng.nextDouble();

    if (m >= 80 && roll < 0.09) return ObjectKind.diamond;
    if (m >= 120 && roll < 0.10) return ObjectKind.pathSpike;
    if (m >= 200 && roll < 0.11) return ObjectKind.stalactite;
    if (m >= 900 && roll < 0.05) return ObjectKind.dynamite;
    if (m >= 600 && roll < 0.07) return ObjectKind.spider;
    if (m >= 600 && roll < 0.11) return ObjectKind.goldNugget;
    if (m >= 300 && roll < 0.14) return ObjectKind.woodBeam;
    if (m >= 150 && roll < 0.18) return ObjectKind.debris;

    return switch (biome) {
      BiomeKind.classicMine => _rockWeighted(),
      BiomeKind.crystalCave =>
        m >= 300 && roll < 0.35 ? ObjectKind.diamond : _rockWeighted(),
      BiomeKind.goldenMine =>
        m >= 600 && roll < 0.28 ? ObjectKind.goldNugget : _rockWeighted(),
      BiomeKind.abandonedMine =>
        m >= 300 && roll < 0.22 ? ObjectKind.woodBeam : _rockWeighted(),
      BiomeKind.lavaCave =>
        m >= 900 && roll < 0.18 ? ObjectKind.dynamite : _rockWeighted(),
      BiomeKind.ancientRuins => _rockWeighted(),
    };
  }

  ObjectKind _rockWeighted() {
    final m = _difficulty.distanceMeters;

    ObjectKind tierForDistance() {
      if (m < 200) return ObjectKind.rockSmall;
      if (m < 600) return ObjectKind.rockMedium;
      return ObjectKind.rockLarge;
    }

    ObjectKind pickTier() {
      final r = _rng.nextDouble();
      if (r < 0.55) return ObjectKind.rockMedium;
      if (r < 0.78) return ObjectKind.rockSmall;
      return ObjectKind.rockLarge;
    }

    ObjectKind adjacent(ObjectKind k) => switch (k) {
          ObjectKind.rockSmall => ObjectKind.rockMedium,
          ObjectKind.rockLarge => ObjectKind.rockMedium,
          _ => _rng.nextBool() ? ObjectKind.rockSmall : ObjectKind.rockLarge,
        };

    ObjectKind next;
    if (_lastRockKind == null) {
      next = tierForDistance();
    } else {
      final r = _rng.nextDouble();
      if (r < 0.68) {
        next = _lastRockKind!;
      } else if (r < 0.90) {
        next = adjacent(_lastRockKind!);
      } else {
        next = pickTier();
      }
    }

    _lastRockKind = next;
    return next;
  }

  double _aheadCenterX([double screenWidth = GameConfig.worldWidth]) {
    final minerX = GameConfig.minerX;
    final lo = screenWidth * 0.08;
    final hi = screenWidth * 0.92;
    final ahead = minerX +
        screenWidth *
            (GameConfig.spawnAheadMinFrac +
                _rng.nextDouble() *
                    (GameConfig.spawnAheadMaxFrac -
                        GameConfig.spawnAheadMinFrac));
    return ahead.clamp(lo, hi);
  }

  bool rollHomingFor(ObjectKind kind) {
    if (kind.isGroundHazard) return false;
    // Everything from the ceiling telegraphs toward the miner.
    return true;
  }

  bool rollHoming() => true;

  double _aimStrength(ObjectKind kind) {
    if (kind.isSliceCrystal || kind == ObjectKind.goldNugget) return 0.36;
    if (kind == ObjectKind.rockSmall ||
        kind == ObjectKind.rockMedium ||
        kind == ObjectKind.rockLarge ||
        kind == ObjectKind.objRock) {
      return 0.46;
    }
    if (kind == ObjectKind.dynamite || kind == ObjectKind.objDynamite) {
      return 0.58;
    }
    return 0.52;
  }

  ({double vx, double vy, double vr}) velocityFor(
    ObjectKind kind, {
    required double spawnX,
    required double spawnY,
    required double headX,
    required double headY,
    bool homing = false,
  }) {
    if (kind.isGroundHazard) {
      final scroll = _difficulty.bgScrollSpeed;
      return (vx: -scroll * 1.05, vy: 0, vr: 0);
    }

    final speed = _difficulty.fallSpeed;
    final dx = headX - spawnX;
    final dy = headY - spawnY;
    final len = math.max(80.0, math.sqrt(dx * dx + dy * dy));
    final aim = _aimStrength(kind);

    // Arc from ceiling ahead → miner (mine is crumbling onto you).
    var vy = speed * (0.42 + (dy / len).clamp(0.2, 1.0) * aim);
    var vx = (dx / len) * speed * aim;
    vx += (_rng.nextDouble() - 0.5) * speed * 0.06;
    vx -= _difficulty.bgScrollSpeed * (0.08 + _rng.nextDouble() * 0.06);

    if (homing && aim < 0.55) {
      vx += (dx / len) * speed * 0.06;
      vy += (dy / len) * speed * 0.04;
    }

    if (kind == ObjectKind.bossSpider) {
      vy *= 0.78;
      vx += ((headX - spawnX) * 0.08).clamp(-40.0, 40.0);
    }
    if (kind.isStalactite) {
      vy *= 1.12;
      vx *= 0.3;
    }
    if (kind == ObjectKind.objSaw) {
      vy *= 1.08;
      vx *= 0.85;
    }
    if (kind == ObjectKind.rockSmall ||
        kind == ObjectKind.rockMedium ||
        kind == ObjectKind.rockLarge ||
        kind == ObjectKind.objRock) {
      vy *= 0.72;
    } else if (kind == ObjectKind.objCrate) {
      vy *= 0.88;
    }
    if (kind == ObjectKind.objCrystal ||
        kind == ObjectKind.diamond ||
        kind == ObjectKind.goldNugget) {
      vy *= 0.88;
    }

    var spin = _difficulty.rotationSpeed;
    if (kind == ObjectKind.dynamite || kind == ObjectKind.objDynamite) {
      spin *= 2.0;
    } else if (kind == ObjectKind.objSaw) {
      spin *= 2.6;
    } else if (kind == ObjectKind.objCrate) {
      spin *= 0.65;
    }

    final vr = kind.isStalactite
        ? (_rng.nextDouble() - 0.5) * 0.6
        : (_rng.nextDouble() - 0.5) * spin;
    return (vx: vx, vy: vy, vr: vr);
  }

  /// Pick an X lane. Often near the miner so head-tops are real threats.
  double spawnX(
    double screenWidth,
    double minerX, {
    List<double> occupiedXs = const [],
    bool avoidMinerLane = false,
  }) {
    final lo = screenWidth * 0.08;
    final hi = screenWidth * 0.92;

    // Runner sky-line: 3 columns ahead, tight spacing.
    if (_lineMode == _LineMode.horizontal && _lineCenterX != null) {
      const colGap = 112.0;
      final x = (_lineCenterX! + (_patternIdx - 1) * colGap).clamp(lo, hi);
      _lastSpawnX = x;
      return x;
    }

    // Vertical train — one stalactite column.
    if (_lineMode == _LineMode.vertical && _lineCenterX != null) {
      final x = _lineCenterX!.clamp(lo, hi);
      _lastSpawnX = x;
      return x;
    }

    // Diagonal wave — stepping right as they telegraph forward.
    if (_lineMode == _LineMode.diagonal && _lineCenterX != null) {
      final x = (_lineCenterX! + _patternIdx * 78).clamp(lo, hi);
      _lastSpawnX = x;
      return x;
    }

    // Pattern fan: spread ahead of the miner, not full-screen random.
    if (_patternCount > 1) {
      final center = _aheadCenterX(screenWidth);
      final spread = screenWidth * GameConfig.spawnAheadSpreadFrac;
      final t = _patternCount <= 1
          ? 0.0
          : (_patternIdx / (_patternCount - 1) - 0.5);
      final x = (center + t * spread + (_rng.nextDouble() - 0.5) * 28)
          .clamp(lo, hi);
      _lastSpawnX = x;
      return x;
    }

    // Default: ceiling ahead of runner — player sees it will land on them.
    for (var attempt = 0; attempt < 16; attempt++) {
      final center = _aheadCenterX(screenWidth);
      final spread = screenWidth * GameConfig.spawnAheadSpreadFrac;
      final x = (center + (_rng.nextDouble() - 0.5) * spread * 2).clamp(lo, hi);

      var ok = true;
      for (final ox in occupiedXs) {
        if ((x - ox).abs() < GameConfig.minLaneGapPx * 0.55) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      if ((_lastSpawnX + 1) > 0 &&
          (x - _lastSpawnX).abs() < GameConfig.minLaneGapPx * 0.65) {
        continue;
      }
      _lastSpawnX = x;
      return x;
    }

    final fallback = _aheadCenterX(screenWidth);
    _lastSpawnX = fallback;
    return fallback;
  }

  /// Higher start — long telegraph from the ceiling.
  double spawnY(int liveThreats) {
    if (_lineMode == _LineMode.horizontal) {
      return -GameConfig.spawnCeilingMinY -
          _patternIdx * 18 -
          _rng.nextDouble() * 30;
    }
    if (_lineMode == _LineMode.vertical) {
      return -GameConfig.spawnCeilingMinY -
          _patternIdx * 100 -
          _rng.nextDouble() * 25;
    }
    if (_lineMode == _LineMode.diagonal) {
      return -GameConfig.spawnCeilingMinY -
          _patternIdx * 28 -
          _rng.nextDouble() * 22;
    }

    final base = -GameConfig.spawnCeilingMinY -
        _rng.nextDouble() *
            (GameConfig.spawnCeilingMaxY - GameConfig.spawnCeilingMinY);
    final patternLift = _patternCount > 1 ? _patternIdx * 16.0 : 0.0;
    return base -
        liveThreats * (55.0 + _rng.nextDouble() * 30) -
        patternLift;
  }
}
