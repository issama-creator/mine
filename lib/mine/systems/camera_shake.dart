import 'dart:math' as math;
import 'dart:ui';

/// Impact shake (mostly horizontal) + soft run bob without vertical hop.
class CameraShake {
  double _t = 0;
  double _duration = 0.15;
  double _mag = 0;
  double _runT = 0;
  bool runBobEnabled = false;
  Offset offset = Offset.zero;
  final _rng = math.Random();

  void bump(double magnitude, {double duration = 0.15}) {
    // Cap + no vertical yank — path run stays flat.
    _mag = math.max(_mag, math.min(magnitude, 5));
    _duration = duration;
    _t = duration;
  }

  void update(
    double dt, {
    double bobAmpX = 0.0,
    double bobAmpY = 0.0,
    double bobPeriod = 0.44,
  }) {
    _runT += dt;
    Offset bob = Offset.zero;
    if (runBobEnabled && (bobAmpX != 0 || bobAmpY != 0)) {
      final phase = _runT * math.pi * 2 / bobPeriod;
      bob = Offset(math.sin(phase) * bobAmpX, math.cos(phase) * bobAmpY);
    }

    if (_t <= 0) {
      offset = bob;
      _mag = 0;
      return;
    }
    _t -= dt;
    final f = (_t / _duration).clamp(0.0, 1.0);
    final ease = f * f;
    // Horizontal-only shake so miner never leaves the road plane.
    offset = Offset(
      bob.dx + (_rng.nextDouble() * 2 - 1) * _mag * ease * 0.35,
      bob.dy,
    );
  }
}
