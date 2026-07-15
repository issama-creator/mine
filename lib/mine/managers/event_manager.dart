import 'dart:math' as math;

import '../core/game_config.dart';
import '../models/game_event.dart';

/// Schedules random gameplay events every ~15–20 seconds.
class EventManager {
  EventManager(this._rng);

  final math.Random _rng;
  double _nextAt = GameConfig.eventFirstDelay;
  GameEventKind? active;
  double _remaining = 0;

  void reset() {
    _nextAt = GameConfig.eventFirstDelay;
    active = null;
    _remaining = 0;
  }

  void tick(double dt, void Function(GameEventKind kind) onStart) {
    if (active != null) {
      _remaining -= dt;
      if (_remaining <= 0) active = null;
      return;
    }

    _nextAt -= dt;
    if (_nextAt > 0) return;

    _nextAt = GameConfig.eventMinInterval +
        _rng.nextDouble() *
            (GameConfig.eventMaxInterval - GameConfig.eventMinInterval);
    active = GameEventKind.values[_rng.nextInt(GameEventKind.values.length)];
    _remaining = GameConfig.eventDuration;
    onStart(active!);
  }

  bool get isActive => active != null;

  GameEventKind? get current => active;
}

/// Boss spider every 1000–1500 m.
class BossManager {
  BossManager(this._rng);

  final math.Random _rng;
  double _nextBossAt = 0;
  bool _pendingBoss = false;

  void reset() {
    _nextBossAt = GameConfig.bossMinDistance +
        _rng.nextDouble() *
            (GameConfig.bossMaxDistance - GameConfig.bossMinDistance);
    _pendingBoss = false;
  }

  void tick(double distanceMeters) {
    if (distanceMeters >= _nextBossAt) _pendingBoss = true;
  }

  bool consumeBossSpawn(double currentDistance) {
    if (!_pendingBoss) return false;
    _pendingBoss = false;
    _nextBossAt = currentDistance +
        GameConfig.bossMinDistance +
        _rng.nextDouble() *
            (GameConfig.bossMaxDistance - GameConfig.bossMinDistance);
    return true;
  }
}
