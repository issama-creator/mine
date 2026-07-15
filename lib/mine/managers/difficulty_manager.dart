import 'dart:math' as math;

import '../core/game_config.dart';
import '../models/mine_background.dart';
import '../models/biome_kind.dart';

class DifficultyManager {
  double distanceMeters = 0;
  double runTime = 0;

  double get spawnInterval {
    // Start comfortable for tapping; late-game still readable.
    final t = (distanceMeters / 1400).clamp(0.0, 1.0);
    return 1.55 - t * 0.45; // ~1.55s → ~1.10s
  }

  double get fallSpeed {
    final t = (distanceMeters / 1500).clamp(0.0, 1.0);
    return 180 + t * 220;
  }

  double get angleSpread {
    final t = (distanceMeters / 1000).clamp(0.0, 1.0);
    return 0.35 + t * 0.55;
  }

  double get rotationSpeed {
    final t = (distanceMeters / 900).clamp(0.0, 1.0);
    return 1.5 + t * 4.0;
  }

  BiomeKind get biome => biomeAtDistance(distanceMeters);

  int get biomeIndex =>
      (distanceMeters / GameConfig.biomeIntervalMeters).floor();

  /// 1 → ~2.15 as you go further — drives background / distance / pressure.
  /// Miner leg anim stays independent (smooth constant cadence).
  double get speedScale {
    final t = (distanceMeters / GameConfig.speedRampMeters).clamp(0.0, 1.0);
    final eased = t * t * (3 - 2 * t); // smoothstep
    return 1.0 + (GameConfig.speedScaleMax - 1.0) * eased;
  }

  double get metersPerSecond => GameConfig.metersPerSecond * speedScale;

  /// Only the world rolls faster — not the run-cycle step time.
  double get bgScrollSpeed => GameConfig.bgScrollSpeed * speedScale;

  void tick(double dt) {
    runTime += dt;
    distanceMeters += metersPerSecond * dt;
  }
}

/// Biome swap triggers at the START of each distance segment (e.g. 400 m).
class BiomeManager {
  BiomeManager(this._difficulty);

  final DifficultyManager _difficulty;

  BiomeKind _from = BiomeKind.classicMine;
  BiomeKind _to = BiomeKind.classicMine;
  int _fromBg = 0;
  int _toBg = 0;
  int _lastBiomeIndex = -1;

  /// 0 = just started transition, 1 = settled on [_to].
  double _t = 1;

  BiomeKind get current => _to;
  BiomeKind get from => _from;
  BiomeKind get to => _to;
  int get fromBgIndex => _fromBg;
  int get toBgIndex => _toBg;

  /// Ease-ready linear 0…1 while transitioning.
  double get transitionT => _t;

  bool get isTransitioning => _t < 1;

  void reset() {
    _from = BiomeKind.classicMine;
    _to = BiomeKind.classicMine;
    _fromBg = 0;
    _toBg = 0;
    _lastBiomeIndex = -1;
    _t = 1;
  }

  void update(double dt) {
    final idx = _difficulty.biomeIndex;
    if (idx != _lastBiomeIndex) {
      _lastBiomeIndex = idx;
      final target = biomeAtDistance(_difficulty.distanceMeters);
      final targetBg = MineBackground.indexAtDistance(_difficulty.distanceMeters);
      if (target != _to || targetBg != _toBg) {
        _from = _to;
        _to = target;
        _fromBg = _toBg;
        _toBg = targetBg;
        _t = 0;
      }
    }

    if (_t < 1) {
      _t = math.min(1, _t + dt / GameConfig.biomeFadeSeconds);
    }
  }
}
