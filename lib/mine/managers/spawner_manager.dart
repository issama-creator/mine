import 'dart:math' as math;

import '../core/game_config.dart';
import '../managers/difficulty_manager.dart';
import '../managers/event_manager.dart';
import '../models/biome_kind.dart';
import '../models/game_event.dart';
import '../models/object_kind.dart';

class SpawnerManager {
  SpawnerManager(this._rng, this._difficulty, this._events, this._bosses);

  final math.Random _rng;
  final DifficultyManager _difficulty;
  final EventManager _events;
  final BossManager _bosses;

  double _timer = 1.0;
  double _sinceLastSpawn = 99;
  int _rockfallBurst = 0;

  /// Last chosen spawn X — helps keep consecutive rains apart.
  double _lastSpawnX = -999;

  void reset() {
    _timer = 1.2;
    _sinceLastSpawn = 99;
    _rockfallBurst = 0;
    _lastSpawnX = -999;
  }

  void _doSpawn(void Function(ObjectKind kind) spawn, ObjectKind kind) {
    spawn(kind);
    _sinceLastSpawn = 0;
  }

  /// Fair rain: max 3, spaced in time + lanes — never a 4-wall on the head.
  void tick(
    double dt,
    void Function(ObjectKind kind) spawn, {
    int liveThreats = 0,
  }) {
    _bosses.tick(_difficulty.distanceMeters);
    _sinceLastSpawn += dt;
    _timer -= dt;

    if (liveThreats >= GameConfig.maxLiveThreats) {
      _timer = math.max(_timer, 0.2);
      return;
    }

    if (_sinceLastSpawn < GameConfig.minSpawnGap) {
      return;
    }

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

    _doSpawn(spawn, _pickKind(event));
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

  ObjectKind _pickKind(GameEventKind? event) {
    final m = _difficulty.distanceMeters;
    final biome = _difficulty.biome;

    if (event != null) {
      return switch (event) {
        GameEventKind.crystalRain =>
          _rng.nextDouble() < 0.65 ? ObjectKind.diamond : ObjectKind.goldNugget,
        GameEventKind.spiderNest => ObjectKind.spider,
        GameEventKind.treasureRush => _rng.nextDouble() < 0.5
            ? ObjectKind.diamond
            : ObjectKind.goldNugget,
        GameEventKind.dynamiteZone => ObjectKind.dynamite,
        GameEventKind.rockfall => _rockWeighted(),
      };
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
    final r = _rng.nextDouble();
    if (m < 300) return ObjectKind.rockSmall;
    if (r < 0.4) return ObjectKind.rockSmall;
    if (r < 0.75) return ObjectKind.rockMedium;
    return ObjectKind.rockLarge;
  }

  ({double vx, double vy, double vr}) velocityFor(
    ObjectKind kind, {
    required double spawnX,
    required double spawnY,
    required double headX,
    required double headY,
  }) {
    if (kind.isGroundHazard) {
      final scroll = _difficulty.bgScrollSpeed;
      return (vx: -scroll * 1.05, vy: 0, vr: 0);
    }

    final speed = _difficulty.fallSpeed;

    // Rain: mostly DOWN, soft drift — NOT aimed at head.
    var vy = speed * (0.65 + _rng.nextDouble() * 0.35);
    var vx = (_rng.nextDouble() - 0.5) * speed * 0.28;
    vx -= _difficulty.bgScrollSpeed * (0.1 + _rng.nextDouble() * 0.1);

    if (kind == ObjectKind.bossSpider) {
      vy *= 0.78;
      vx += ((headX - spawnX) * 0.08).clamp(-40.0, 40.0);
    }
    if (kind.isStalactite) {
      vy *= 1.12;
      vx *= 0.3;
    }

    final vr = kind.isStalactite
        ? (_rng.nextDouble() - 0.5) * 0.6
        : (_rng.nextDouble() - 0.5) *
            _difficulty.rotationSpeed *
            (kind == ObjectKind.dynamite ? 2 : 1);
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

    // ~25% near miner; rest rain across the full sky (tappable anywhere).
    if (!avoidMinerLane && _rng.nextDouble() < 0.25) {
      final band = screenWidth * 0.18;
      final x =
          (minerX + (_rng.nextDouble() - 0.55) * band * 2).clamp(lo, hi);
      var blocked = false;
      for (final ox in occupiedXs) {
        if ((x - ox).abs() < GameConfig.minLaneGapPx * 0.65) {
          blocked = true;
          break;
        }
      }
      if (!blocked) {
        _lastSpawnX = x;
        return x;
      }
    }

    double? best;
    var bestScore = -1.0;
    final minerHalf = screenWidth * 0.10;

    for (var attempt = 0; attempt < 14; attempt++) {
      final x = lo + _rng.nextDouble() * (hi - lo);
      if (avoidMinerLane && (x - minerX).abs() < minerHalf) continue;

      var ok = true;
      var nearest = 9999.0;
      for (final ox in occupiedXs) {
        final d = (x - ox).abs();
        if (d < nearest) nearest = d;
        if (d < GameConfig.minLaneGapPx) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      if ((_lastSpawnX + 1) > 0 &&
          (x - _lastSpawnX).abs() < GameConfig.minLaneGapPx * 0.8) {
        continue;
      }

      // Prefer free space — do NOT push away from the miner.
      if (nearest > bestScore) {
        bestScore = nearest;
        best = x;
      }
    }

    final x = best ?? ((lo + hi) * 0.5);
    _lastSpawnX = x;
    return x;
  }

  /// Higher start when others already falling — vertical stagger, not a wall.
  double spawnY(int liveThreats) {
    final base = -40.0 - _rng.nextDouble() * 70;
    return base - liveThreats * (70.0 + _rng.nextDouble() * 40);
  }
}
